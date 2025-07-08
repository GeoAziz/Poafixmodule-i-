import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/user_model.dart';

class AuthService {
  // API Constants - Remove space in URL
  static const String baseUrl = 'http://192.168.0.102';

  // Storage Keys
  static const String TOKEN_KEY = 'auth_token';
  static const String USER_TYPE_KEY = 'user_type';

  // Initialize Flutter Secure Storage
  static final _secureStorage = FlutterSecureStorage();

  // Debug Mode
  static bool isDebugMode = true;

  static void _debugPrint(String message) {
    if (isDebugMode) print(message);
  }

  // Helper method to construct API URLs correctly
  static String _buildUrl(String path) {
    // Remove any leading slashes from path to avoid doubles
    path = path.replaceFirst(RegExp(r'^/+'), '');
    return '$baseUrl/api/$path';
  }

  // Authentication
  static Future<Map<String, dynamic>> loginWithEmail(
      String email, String password) async {
    try {
      _debugPrint('Login Request:');
      _debugPrint('Email: $email');

      final Map<String, String> payload = {
        'email': email.trim(),
        'password': password,
      };

      // Try provider login
      var response = await http.post(
        Uri.parse('$baseUrl/api/providers/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      _debugPrint('Provider login response status: ${response.statusCode}');
      _debugPrint('Provider login response body: ${response.body}');

      // If provider login succeeds
      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        return {
          'success': true,
          'token': responseData['token'],
          'userType': responseData['userType'] ?? 'service-provider',
          'user': responseData['provider']
        };
      }

      // If not found as provider, try client login
      response = await http.post(
        Uri.parse('$baseUrl/api/clients/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      _debugPrint('Client login response status: ${response.statusCode}');
      _debugPrint('Client login response body: ${response.body}');

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        return {
          'success': true,
          'token': responseData['token'],
          'userType': responseData['userType'] ?? 'client',
          'user': responseData['client']
        };
      }

      // If both logins fail, throw error
      throw Exception('Login failed: Invalid credentials');
    } catch (e) {
      _debugPrint('Login error in service: $e');
      throw Exception('Failed to log in: $e');
    }
  }

  // Helper method to sanitize map data
  static Map<String, String> _sanitizeMapData(Map<String, dynamic> data) {
    Map<String, String> sanitized = {};
    data.forEach((key, value) {
      if (value != null) {
        sanitized[key] = value.toString();
      }
    });
    return sanitized;
  }

  static Future<Map<String, dynamic>> signUpServiceProvider(User user) async {
    try {
      final String url = _buildUrl(
          'providers/signup'); // Use correct endpoint for provider signup

      final requestData = user.toMap();
      requestData['userType'] = 'provider';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      return await _handleSignupResponse(response);
    } catch (e) {
      _debugPrint('Service Provider Signup error: $e');
      throw Exception('Failed to create service provider account: $e');
    }
  }

  static Future<Map<String, dynamic>> signUpClient(User user) async {
    try {
      final String url = _buildUrl('auth/signup/client');

      final requestData = user.toMap();
      requestData['userType'] = 'client';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      return await _handleSignupResponse(response);
    } catch (e) {
      _debugPrint('Client Signup error: $e');
      throw Exception('Failed to create client account: $e');
    }
  }

  static Future<Map<String, dynamic>> _handleSignupResponse(
      http.Response response) async {
    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(errorData['error'] ?? 'Failed to create account');
    }
  }

  // Storage Management
  static Future<void> _saveAuthData(String token, String userType) async {
    await _secureStorage.write(key: TOKEN_KEY, value: token);
    await _secureStorage.write(key: USER_TYPE_KEY, value: userType);
  }

  // Session Management
  static Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: TOKEN_KEY);
    return token != null; // If token exists, the user is authenticated
  }

  static Future<void> signOut() async {
    await _secureStorage.delete(key: TOKEN_KEY);
    await _secureStorage.delete(key: USER_TYPE_KEY);
  }

  // Fetch user credentials from Secure Storage
  static Future<Map<String, String?>> getUserCredentials() async {
    String? token = await _secureStorage.read(key: TOKEN_KEY);
    String? userType = await _secureStorage.read(key: USER_TYPE_KEY);
    return {'token': token, 'userType': userType};
  }
}
