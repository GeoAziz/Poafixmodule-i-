import 'package:flutter/foundation.dart';
import '../models/user_model.dart'; // Make sure this points to the correct location
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  User? _user; // Changed from UserModel to User
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  String? _authToken;

  // Getters
  User? get user => _user; // Changed from UserModel to User
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String get authToken => _authToken ?? '';

  // Assuming User has a 'type' field to represent the userType
  String get userType =>
      _user?.userType ?? 'guest'; // Default to 'guest' if no user

  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {
    final authService = AuthService();
    return await _authenticate(
      action: () => authService.signUpWithEmail(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber ?? '',
        address: '', // Provide actual address if available
        location: {}, // Provide actual location if available
      ),
    );
  }

  // Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return await _authenticate(
      action: () => AuthService.loginWithEmail(email, password),
    );
  }

  // Logout
  Future<void> logout() async {
    _setLoadingState(true);
    try {
      await AuthService.signOut();
      _clearUserData();
    } catch (e) {
      _error = 'Logout failed: $e';
    } finally {
      _setLoadingState(false);
    }
  }

  // Private helper methods

  // Centralized authentication flow for both login and sign-up
  Future<bool> _authenticate({
    required Future<Map<String, dynamic>> Function() action,
  }) async {
    _setLoadingState(true);
    try {
      final response = await action();
      return _handleAuthResponse(response);
    } catch (e) {
      return _handleAuthError(e.toString());
    }
  }

  // Set loading state
  void _setLoadingState(bool isLoading) {
    _isLoading = isLoading;
    _error = null;
    notifyListeners();
  }

  // Handle authentication response (either login or sign up)
  bool _handleAuthResponse(Map<String, dynamic> response) {
    print('API Response: $response'); // Print API response for debugging
    if (response['success']) {
      try {
        // Parse the user data safely
        _user =
            User.fromJson(response['data']); // Changed from UserModel to User
        _authToken = response['token'];
        _isAuthenticated = true;

        _saveAuthToken(_authToken!);
        _setLoadingState(false);
        return true;
      } catch (e) {
        _error = 'Error parsing user data: $e';
        _setLoadingState(false);
        return false;
      }
    } else {
      _error =
          'Authentication failed: ${response['message'] ?? 'Unknown error'}';
      _setLoadingState(false);
      return false;
    }
  }

  // Handle error during authentication
  bool _handleAuthError(String errorMessage) {
    _error = 'Authentication failed: $errorMessage';
    _setLoadingState(false);
    return false;
  }

  // Save authentication token to SharedPreferences
  Future<void> _saveAuthToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear user data and authentication state
  void _clearUserData() {
    _user = null;
    _authToken = null;
    _isAuthenticated = false;

    _clearAuthToken();
  }

  // Remove authentication token from SharedPreferences
  Future<void> _clearAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
