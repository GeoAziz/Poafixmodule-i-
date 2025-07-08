import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_storage.dart';
import '../models/user_model.dart'; // Update import
import 'auth/login_screen.dart';
import 'home/home_screen.dart' as client;
import 'service_provider/service_provider_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authStorage = AuthStorage();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Show splash for minimum time
      await Future.delayed(Duration(seconds: 2));

      if (!mounted) return;

      final credentials = await _authStorage.getCredentials();

      final token = credentials['auth_token'];
      final userType = credentials['userType'];
      final userId = credentials['user_id'];

      // Debug logs
      print('Checking stored credentials:');
      print('Token exists: ${token != null}');
      print('UserType: $userType');
      print('UserID: $userId');

      if (token == null || userType == null || userId == null) {
        _navigateToLogin();
        return;
      }

      // Navigate based on user type
      if (userType == 'provider') {
        _navigateToProviderScreen(credentials);
      } else {
        _navigateToHomeScreen(credentials);
      }
    } catch (e) {
      print('Error in splash screen: $e');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _navigateToHomeScreen(Map<String, String?> credentials) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => client.HomeScreen(
          // Use prefix
          user: User(
            // Use imported User model
            id: credentials['user_id'] ?? '',
            name: credentials['name'] ?? '',
            email: credentials['email'] ?? '',
            userType: credentials['userType'] ?? '',
          ),
        ),
      ),
    );
  }

  void _navigateToProviderScreen(Map<String, String?> credentials) {
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/loading.json',
              height: 200,
              width: 200,
              repeat: true,
            ),
            SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
