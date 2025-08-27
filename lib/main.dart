import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'models/user_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart' as client;
import 'services/auth_storage.dart';
import 'services/api_config.dart';
import 'services/network_service.dart';
import 'services/app_lifecycle_handler.dart';
//import 'screens/enhanced_booking_screen.dart';
import 'screens/notifications/provider_notifications_screen.dart';
import 'screens/client/client_notifications_screen.dart';
import 'services/notification_service.dart';
import 'package:provider/provider.dart';
import 'services/notification_count_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/bookings/bookings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 Initializing PoaFix App...');
  // Load persisted base URL before anything else
  await NetworkService().loadPersistedBaseUrl();
  // Immediately persist the loaded base URL if valid
  final loadedBaseUrl = NetworkService().baseUrl;
  if (loadedBaseUrl != null && loadedBaseUrl.isNotEmpty) {
    print('[main.dart] Persisting loaded baseUrl at startup: $loadedBaseUrl');
    NetworkService().baseUrl = loadedBaseUrl;
  } else {
    print(
      '[main.dart] No valid baseUrl loaded at startup, will attempt discovery.',
    );
  }
  // Automatically select env file based on build mode
  final envFile = kReleaseMode ? ".env.production" : ".env.development";
  print('[main.dart] Awaiting network discovery...');
  await ApiConfig.initialize(envFile: envFile);
  // After discovery, explicitly assign and persist the discovered base URL
  final discoveredBaseUrl = ApiConfig.baseUrl;
  if (discoveredBaseUrl != null && discoveredBaseUrl.isNotEmpty) {
    print(
      '[main.dart] Persisting discovered baseUrl after network discovery: $discoveredBaseUrl',
    );
    NetworkService().baseUrl = discoveredBaseUrl;
  } else {
    print('[main.dart] No valid baseUrl discovered after network discovery.');
  }
  print('[main.dart] Network discovery complete.');
  final networkStatus = await ApiConfig.getNetworkStatus();
  print('🌐 Network Status: $networkStatus');
  runApp(PoaFixAppWithSplash());
}

class PoaFixAppWithSplash extends StatefulWidget {
  const PoaFixAppWithSplash({Key? key}) : super(key: key);
  @override
  State<PoaFixAppWithSplash> createState() => _PoaFixAppWithSplashState();
}

class _PoaFixAppWithSplashState extends State<PoaFixAppWithSplash> {
  bool _showSplash = true;

  void _finishSplash() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _showSplash
          ? AnimatedSplashScreen(
              logoPath: 'assets/poafix_logo.jpg',
              tagline: 'Fixing Life, One Service at a Time',
              lottiePath: 'assets/animations/services.json',
              onFinish: _finishSplash,
            )
          : const PoaFixApp(),
    );
  }
}

class PoaFixApp extends StatelessWidget {
  const PoaFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationCountProvider()),
        // Add other providers here if needed
      ],
      child: MaterialApp(
        title: 'PoaFix',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        home: AuthenticationWrapper(),
        routes: {
          '/notifications': (context) => ClientNotificationsScreen(),
          '/bookings': (context) {
            final user = ModalRoute.of(context)!.settings.arguments as User;
            // Import BookingsScreen at the top if not already
            return BookingsScreen(user: user);
          },
          // Add other static routes here if needed
        },
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  final Widget child;
  const AppRoot({required this.child});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void dispose() {
    // Disconnect WebSocket on app close
    NotificationService().disconnectWebSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  _AuthenticationWrapperState createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  final _authStorage = AuthStorage();
  bool _isLoading = true;
  String? _error;
  Map<String, String?>? _credentials;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final credentials = await _authStorage.getCredentials();
      setState(() {
        _credentials = credentials;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              ElevatedButton(
                onPressed: () => _checkAuthStatus(),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_credentials != null) {
      final token = _credentials!['auth_token'];
      final userType = _credentials!['userType'];
      final userId = _credentials!['user_id'];

      if (token == null || userType == null || userId == null) {
        return LoginScreen();
      }

      if (userType == 'provider') {
        return ProviderNotificationsScreen();
      } else if (userType == 'client') {
        final user = User(
          id: _credentials!['user_id'] ?? '',
          name: _credentials!['name'] ?? '',
          email: _credentials!['email'] ?? '',
          userType: _credentials!['userType'] ?? '',
          phone: _credentials!['phone'] ?? '',
          token: _credentials!['auth_token'],
          avatarUrl: _credentials!['avatar_url'] ?? '',
        );
        // Wrap AppLifecycleHandler with a widget that implements Widget
        return Builder(
          builder: (context) => AppLifecycleHandler(
            user: user,
            childWidget: client.HomeScreen(user: user),
          ),
        );
      } else {
        return LoginScreen();
      }
    }

    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
