import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:poafix/screens/service_provider/service_provider_screen.dart'
    as sp;
import 'package:poafix/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:poafix/config/api_config.dart';
import '../home/home_screen.dart';
import '../../models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _passwordVisible = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    // Debug: Print API configuration
    print('API Configuration:');
    print('Base URL: [32m${ApiConfig.baseUrl}[0m');
    ApiConfig.printConnectionInfo();
    print('Login endpoint: ${ApiConfig.baseUrl}/auth/login');
  }

  @override
  void dispose() {
    _animController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+[0m').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      print('Attempting login with ${emailController.text}');
      final response = await AuthService.loginWithEmail(
        emailController.text.trim(),
        passwordController.text,
      );
      if (!mounted) return;
      if (response['userType'] == 'service-provider') {
        await AuthService.saveProviderAuthData(response);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => sp.ServiceProviderScreen(
              userName: response['provider']['businessName'] ?? '',
              userId: response['provider']['id'] ?? '',
              businessName: response['provider']['businessName'] ?? '',
              serviceType: response['provider']['serviceType'] ?? 'general',
            ),
          ),
        );
      } else {
        await AuthService.saveAuthData(response);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              user: User(
                id: response['user']['id'],
                name: response['user']['name'],
                email: response['user']['email'],
                userType: 'client',
                phoneNumber: response['user']['phoneNumber'],
                token: response['token'],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print('Login error: $e');
      if (mounted) {
        _showError('Invalid credentials. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo with Lottie
                  SizedBox(
                    height: 100,
                    child: Lottie.asset(
                      'assets/animations/profile.json',
                      repeat: true,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/poafix_logo.jpg',
                        width: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome Back!',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  // Email field with validation
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  // Password field with toggle
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_passwordVisible,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _showError('Forgot password feature coming soon!');
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: theme.primaryColor,
                      ),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Don\'t have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                  // Image.asset(
                  //   'assets/illustrations/login_illustration.png',
                  //   height: 120,
                  // ),
                  const SizedBox(height: 32),
                  // Modern illustration for visual polish
                  Image.asset(
                    'assets/illustrations/login_illustration.png',
                    height: 120,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Remove or replace empty/corrupt animation files to fix build errors
// The following files are empty and should be deleted or replaced:
//   assets/animations/empty_jobs.json
//   assets/animations/error.json
//   assets/animations/no_notifications.json
//
// Only keep valid, non-empty animation files in assets/animations/.
