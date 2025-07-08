import '../services/api_service.dart';
import '../constants/api_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Login method
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.post(ApiConstants.loginEndpoint,
          data: {'email': email, 'password': password});

      // Store authentication token securely
      await _storage.write(key: 'auth_token', value: response.data['token']);

      return response.data;
    } catch (e) {
      print("Login failed: $e");
      rethrow;
    }
  }

  // Register (Sign-up) method
  Future<void> register(Map<String, dynamic> userData) async {
    try {
      await _apiService.post(ApiConstants.registerEndpoint, data: userData);
    } catch (e) {
      print("Registration failed: $e");
      rethrow;
    }
  }

  // Logout method
  Future<void> logout() async {
    // Clear stored token
    await _storage.delete(key: 'auth_token');
  }

  // Get the current authenticated user (Firebase example)
  Future<User?> getCurrentUser() async {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      print("Failed to get current user: $e");
      rethrow;
    }
  }
}
