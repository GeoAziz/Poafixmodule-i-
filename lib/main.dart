import 'package:flutter/material.dart';
import 'screens/animated_splash_screen.dart';
import 'models/user_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart' as client;
import 'screens/service_provider/service_provider_screen.dart';
import 'services/auth_storage.dart';
import 'screens/bookings/bookings_screen.dart';
import 'services/api_config.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/proximity_service_selection_screen.dart';
import 'screens/enhanced_booking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize network discovery
  print('🚀 Initializing PoaFix App...');
  await ApiConfig.initialize();
  
  // Print network status for debugging
  final networkStatus = await ApiConfig.getNetworkStatus();
  print('🌐 Network Status: $networkStatus');
  
  runApp(const PoaFixApp());
}

class PoaFixApp extends StatelessWidget {
  const PoaFixApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoaFix',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashWrapper(),
      onGenerateRoute: (settings) {
        print('⚡ Generating route for: ${settings.name}');

        return MaterialPageRoute(
          builder: (context) => FutureBuilder(
            future:
                Future.delayed(Duration(milliseconds: 300)), // Smooth transition
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              switch (settings.name) {
                case '/home':
                  final user = settings.arguments as User?;
                  return client.HomeScreen(
                    user: user ?? User.empty(),
                  );

                case '/proximity-services':
                  final user = settings.arguments as User?;
                  return ProximityServiceSelectionScreen(
                    user: user ?? User.empty(),
                  );

                case '/enhanced-booking':
                  final arguments = settings.arguments as Map<String, dynamic>?;
                  return EnhancedBookingScreen(
                    serviceId: arguments?['serviceId'] ?? '',
                    serviceName: arguments?['serviceName'] ?? 'Service',
                    user: arguments?['user'] ?? User.empty(),
                  );

                case '/bookings':
                  final user = settings.arguments as User?;
                  return BookingsScreen(
                    user: user ?? User.empty(),
                    showNavigation: true,
                  );

                case '/profile':
                  final user = settings.arguments as User?;
                  return ProfileScreen(user: user ?? User.empty());

                default:
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Route ${settings.name} not found'),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/home'),
                            child: Text('Go Home'),
                          ),
                        ],
                      ),
                    ),
                  );
              }
            },
          ),
        );
      },
    );
  }
}

class SplashWrapper extends StatefulWidget {
  @override
  _SplashWrapperState createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
  }

  void _finishSplash() {
    setState(() { _showSplash = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return AnimatedSplashScreen(onFinish: _finishSplash);
    }
    return AuthenticationWrapper();
  }
}

class AuthenticationWrapper extends StatefulWidget {
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
        MaterialPageRoute(
          builder: (context) => ServiceProviderScreen(
            userName: credentials['name'] ?? '',
            userId: credentials['user_id'] ?? '',
            businessName: credentials['business_name'] ?? '',
            serviceType: credentials['service_type'] ?? '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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

    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
