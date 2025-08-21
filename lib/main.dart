import 'package:flutter/material.dart';
import 'app_root.dart';
import 'models/user_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart' as client;
import 'screens/profile/profile_screen.dart';
import 'services/auth_storage.dart';
import 'screens/bookings/bookings_screen.dart';
import 'services/api_config.dart';
import 'screens/proximity_service_selection_screen.dart';
import 'screens/enhanced_booking_screen.dart';
import 'screens/notifications/provider_notifications_screen.dart';
import 'screens/enhanced_calendar_screen.dart';
import 'screens/services/service_selection_screen.dart';
import 'screens/client/client_notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize network discovery
  print('🚀 Initializing PoaFix App...');
  await ApiConfig.initialize();

  // Print network status for debugging
  final networkStatus = await ApiConfig.getNetworkStatus();
  print('🌐 Network Status: $networkStatus');

  runApp(AppRoot(child: const PoaFixApp()));
}

class PoaFixApp extends StatelessWidget {
  const PoaFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoaFix',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: AuthenticationWrapper(),
      onGenerateRoute: (settings) {
        print('⚡ Generating route for: ${settings.name}');
        return MaterialPageRoute(
          builder: (context) => FutureBuilder(
            future: Future.delayed(Duration(milliseconds: 300)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              switch (settings.name) {
                case '/home':
                  final user = settings.arguments as User?;
                  return client.HomeScreen(user: user ?? User.empty());
                case '/profile':
                  final user = settings.arguments as User?;
                  if (user != null && user.userType == 'client') {
                    return ProfileScreen(user: user);
                  }
                  return AuthenticationWrapper();
                case '/proximity-services':
                  final user = settings.arguments as User?;
                  return ProximityServiceSelectionScreen(
                    user: user ?? User.empty(),
                  );
                case '/select-service':
                  final user = settings.arguments as User?;
                  return ServiceSelectionScreen(user: user ?? User.empty());
                case '/enhanced-booking':
                  final arguments = settings.arguments as Map<String, dynamic>?;
                  return EnhancedBookingScreen(
                    serviceId: arguments?['serviceId'] ?? '',
                    serviceName: arguments?['serviceName'] ?? 'Service',
                    user: arguments?['user'] ?? User.empty(),
                  );
                case '/calendar':
                  final user = settings.arguments as User?;
                  return EnhancedCalendarScreen(user: user ?? User.empty());
                case '/bookings':
                  final user = settings.arguments as User?;
                  return BookingsScreen(
                    user: user ?? User.empty(),
                    showNavigation: true,
                  );
                default:
                  return Scaffold(
                    body: Center(
                      child: Text(
                        'Route not found: ' + (settings.name ?? 'Unknown'),
                      ),
                    ),
                  );
              }
            },
          ),
        );
      },
      routes: {'/notifications': (context) => ClientNotificationsScreen()},
    );
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

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      print('Checking authentication status...');
      final credentials = await _authStorage.getCredentials();

      final token = credentials['auth_token'];
      final userType = credentials['userType'];
      final userId = credentials['user_id'];

      print('Stored credentials found:');
      print('Token: ${token != null ? 'Present' : 'Missing'}');
      print('UserType: $userType');
      print('UserID: $userId');

      if (token == null || userType == null || userId == null) {
        print('Missing required credentials, redirecting to login');
        _navigateToLogin();
        return;
      }

      // Navigate based on user type
      if (userType == 'provider') {
        print('Provider detected, navigating to provider screen');
        _navigateToProviderScreen(credentials);
      } else if (userType == 'client') {
        print('Client detected, navigating to home screen');
        _navigateToHomeScreen(credentials);
      } else {
        print('Unknown user type: $userType');
        _navigateToLogin();
      }
    } catch (e) {
      print('Error checking auth status: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  void _navigateToHomeScreen(Map<String, String?> credentials) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => client.HomeScreen(
            user: User(
              id: credentials['user_id'] ?? '',
              name: credentials['name'] ?? '',
              email: credentials['email'] ?? '',
              userType: credentials['userType'] ?? '',
              phone: credentials['phone'] ?? '',
              token: credentials['auth_token'],
              avatarUrl: credentials['avatar_url'] ?? '',
            ),
          ),
        ),
      );
    }
  }

  void _navigateToProviderScreen(Map<String, String?> credentials) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProviderNotificationsScreen()),
      );
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

    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
