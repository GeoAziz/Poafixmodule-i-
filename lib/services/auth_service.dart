import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import '../config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart'; // Update import

class AuthResponse {
  final String token;
  final String userType;
  final User user;

  AuthResponse({
    required this.token,
    required this.userType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final user = User.fromJson(json['user'] ?? {});
    return AuthResponse(
      token: json['token'] ?? '',
      userType: json['userType'] ?? '',
      user: user,
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'userType': userType, 'user': user.toJson()};
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static final _storage = FlutterSecureStorage();
  static final AuthStorage _authStorage = AuthStorage();
  final _dio = Dio();

  factory AuthService() => _instance;
  AuthService._internal();

  // Add the baseUrl getter
  static String get baseUrl => ApiConfig.baseUrl;

  Future<String?> getToken() async {
    try {
      // Try multiple token keys
      final token =
          await _storage.read(key: 'auth_token') ??
          await _storage.read(key: 'auth_token');

      print(
        'Debug - Auth Service Token: ${token != null ? 'Found' : 'Not found'}',
      );

      if (token == null) {
        // If no token, try to refresh or re-authenticate
        print('Warning: No auth token found in storage');
      }

      return token;
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<String> getApiUrl() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.isPhysicalDevice) {
      return 'http:// 192.168.0.102/api'; // Replace with your actual IP
    } else {
      return '${ApiConfig.baseUrl}/api'; // Always use dynamic base URL
    }
  }

  static const String authEndpoint = '/auth';
  static const String userEndpoint = '/users';

  static const String TOKEN_KEY = 'auth_token';
  static const String USER_TYPE_KEY = 'user_type';
  static const String USER_DATA_KEY = 'user_data';
  static const String CLIENT_ID_KEY = 'client_id';

  static bool isDebugMode = true;

  static void _debugPrint(String message) {
    if (isDebugMode) print(message);
  }

  static Future<Map<String, dynamic>> _makeRequest(
    String endpoint,
    String method,
    Map<String, dynamic> body,
  ) async {
    try {
      final apiUrl = await getApiUrl();
      final response = await http.post(
        Uri.parse('$apiUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to make request: ${response.body}');
      }
    } catch (e) {
      _debugPrint('Error: $e');
      throw Exception('Failed to make request: $e');
    }
  }

  static Future<Map<String, dynamic>> handleAuthentication(
    Map<String, dynamic> response,
  ) async {
    try {
      // Handle provider registration response format
      if (response['provider'] != null) {
        final provider = response['provider'];
        // Convert provider response to expected format
        final formattedData = {
          'success': response['success'],
          'message': response['message'],
          'token': response['token'] ?? '',
          'userType': 'provider',
          'user': provider,
        };

        // Save auth data
        await AuthService._storage.write(
          key: 'auth_token',
          value: formattedData['token'],
        );
        await AuthService._storage.write(key: 'user_type', value: 'provider');
        await AuthService._storage.write(
          key: 'user_data',
          value: json.encode(provider),
        );

        return formattedData;
      }

      // Handle regular authentication response
      final data = response;
      await AuthService._storage.write(key: 'auth_token', value: data['token']);
      await AuthService._storage.write(
        key: 'user_type',
        value: data['user']?['userType'] ?? 'client',
      );
      await AuthService._storage.write(
        key: 'user_data',
        value: json.encode(data['user']),
      );

      return {
        'token': data['token'],
        'userType': data['user']?['userType'] ?? 'client',
        'user': data['user'],
      };
    } catch (e) {
      print('Error in handleAuthentication: $e');
      throw Exception('Failed to process authentication data');
    }
  }

  Future<Map<String, dynamic>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
    required Map<String, dynamic> location,
    String? profilePicture,
    String? backupContact,
    String? preferredCommunication,
    String? timezone,
    bool isProvider = false,
    String? businessName,
    String? serviceType,
  }) async {
    try {
      final endpoint = isProvider ? 'providers' : 'clients';
      final requestData = {
        'name': name,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'address': address,
        'location': location,
        'backupContact': backupContact,
        'preferredCommunication': preferredCommunication,
        'timezone': timezone,
        if (profilePicture != null) 'profilePicture': profilePicture,
        if (isProvider) ...<String, dynamic>{
          'businessName': businessName,
          'serviceType': serviceType,
          'role': 'provider',
          'userType': 'service-provider',
        },
      };

      final apiUrl = await getApiUrl();
      print(
        '📤 Sending $endpoint signup request: \\${json.encode(requestData)} to $apiUrl',
      );

      final response = await _dio.post(
        '$apiUrl/$endpoint/signup',
        data: requestData,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print('📥 Signup Response: \\${response.data}');

      if (response.statusCode == 400) {
        throw Exception(response.data['message'] ?? 'Signup failed');
      }

      return response.data;
    } catch (e) {
      print('❌ Signup error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> signUpServiceProvider(
    Map<String, dynamic> data,
  ) async {
    try {
      final signupData = {
        'name': data['name'],
        'email': data['email'],
        'password': data['password'],
        'phoneNumber': data['phoneNumber'],
        'address': data['address'],
        'businessName': data['businessName'],
        'serviceType': data['serviceType'],
        'location': {
          'type': 'Point',
          'coordinates': data['location']['coordinates'] ?? [36.8219, -1.2921],
        },
        'role': 'provider',
        'userType': 'service-provider',
        'backupContact': data['backupContact'],
        'preferredCommunication': data['preferredCommunication'],
        'timezone': data['timezone'],
      };

      print('📤 Provider signup data: ${json.encode(signupData)}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/providers/signup'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(signupData),
      );

      print('📥 Provider signup response: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        await saveProviderAuthData(responseData);
        return responseData;
      }

      throw Exception(
        'Signup failed: ${response.statusCode}\n${response.body}',
      );
    } catch (e) {
      print('❌ Provider signup error: $e');
      rethrow;
    }
  }

  // New helper methods for coordinate validation
  static double _parseCoordinate(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    throw Exception('Invalid coordinate value: $value');
  }

  static bool _isValidLatitude(double? lat) {
    return lat != null &&
        !lat.isNaN &&
        !lat.isInfinite &&
        lat >= -90 &&
        lat <= 90;
  }

  static bool _isValidLongitude(double? lng) {
    return lng != null &&
        !lng.isNaN &&
        !lng.isInfinite &&
        lng >= -180 &&
        lng <= 180;
  }

  static Future<Map<String, dynamic>> signupProvider(
    Map<String, dynamic> data,
  ) async {
    try {
      print('Signing up provider with data: $data'); // Debug log

      final endpoint = '${ApiConfig.baseUrl}/auth/signup/provider';
      print('Making request to: $endpoint'); // Debug log

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(data),
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 201) {
        return handleAuthentication(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        if (errorBody['requiredFields'] != null) {
          throw Exception(
            'Missing fields: ${errorBody['requiredFields'].join(", ")}',
          );
        }
        throw Exception(errorBody['error'] ?? 'Failed to create account');
      }
    } catch (e) {
      print('Signup error: $e'); // Debug log
      throw Exception('Failed to create account: $e');
    }
  }

  static Future<Map<String, dynamic>> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      print('🔍 Attempting login for: $email');
      print('🌐 Current base URL: ${ApiConfig.baseUrl}');

      // Test connection before attempting login
      final isConnected = await ApiConfig.testConnection();
      if (!isConnected) {
        print('🔄 Connection failed, refreshing network discovery...');
        await ApiConfig.refreshConnection();

        // Test again after refresh
        final stillNotConnected = !(await ApiConfig.testConnection());
        if (stillNotConnected) {
          throw Exception(
            'Cannot connect to server. Please check your network connection.',
          );
        }
      }

      final loginData = {'email': email.trim(), 'password': password};

      // Try provider login first
      try {
        print('🔄 Trying provider login...');
        final response = await ApiConfig.makeRequest(
          '/api/providers/login',
          method: 'POST',
          body: loginData,
        );

        print('📡 Provider login status: ${response.statusCode}');
        print(
          '📡 Provider response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          await saveProviderAuthData(data);
          return {...data, 'userType': 'service-provider'};
        }
      } catch (e) {
        print('❌ Provider login failed: $e');
      }

      // Try client login
      try {
        print('🔄 Trying client login...');
        final response = await ApiConfig.makeRequest(
          '/api/clients/login',
          method: 'POST',
          body: loginData,
        );

        print('📡 Client login status: ${response.statusCode}');
        print(
          '📡 Client response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          await saveAuthData(data);
          return {...data, 'userType': 'client'};
        }
      } catch (e) {
        print('❌ Client login failed: $e');
      }

      // Try admin login
      try {
        print('🔄 Trying admin login...');
        final response = await ApiConfig.makeRequest(
          '/api/admin/login',
          method: 'POST',
          body: loginData,
        );

        print('📡 Admin login status: ${response.statusCode}');
        print(
          '📡 Admin response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          await saveAuthData(data);
          return {...data, 'userType': 'admin'};
        }
      } catch (e) {
        print('❌ Admin login failed: $e');
      }

      throw Exception('Invalid email or password');
    } catch (e) {
      print('❌ Login error: $e');
      rethrow;
    }
  }

  // Add method to check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      return await verifyAuthState();
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Add method to get stored user data
  static Future<Map<String, String?>> getStoredUserData() async {
    return _authStorage.getCredentials();
  }

  // Helper function to save authentication data (Unchanged)
  static Future<void> _saveAuthData(
    String token,
    String userType,
    String clientId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TOKEN_KEY, token);
    await prefs.setString(USER_TYPE_KEY, userType);
    await prefs.setString(CLIENT_ID_KEY, clientId);
    _debugPrint(
      'Auth data saved: token=$token, userType=$userType, clientId=$clientId',
    );
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final credentials = await getAuthCredentials();
    return (credentials['token']?.isNotEmpty ?? false);
  }

  // Get user type from the saved data
  static Future<String?> getStoredUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(USER_TYPE_KEY);
  }

  // Parse JWT token to extract payload data
  static Map<String, dynamic> _parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token format');
    }

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final resp = json.decode(utf8.decode(base64Url.decode(normalized)));
    return resp;
  }

  // Get the current user from saved preferences
  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(USER_DATA_KEY);
      if (userData != null) {
        return User.fromJson(json.decode(userData));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sign out the user and clear saved data
  static Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(TOKEN_KEY);
      await prefs.remove(USER_TYPE_KEY);
      await prefs.remove(USER_DATA_KEY);
      await prefs.remove(CLIENT_ID_KEY);
      _debugPrint('Signed out successfully');
    } catch (e) {
      _debugPrint('Error during sign out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Fetch user data using the token
  static Future<User?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(TOKEN_KEY);

      if (token == null) {
        throw Exception('No token found');
      }

      final apiUrl = await getApiUrl();
      final response = await http.get(
        Uri.parse('$apiUrl$userEndpoint/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        await prefs.setString(USER_DATA_KEY, json.encode(userData));

        if (userData != null) {
          return User.fromJson(userData);
        } else {
          throw Exception('User data is null');
        }
      } else {
        throw Exception('Failed to fetch user data: ${response.body}');
      }
    } catch (e) {
      _debugPrint('Error: $e');
      throw Exception('Error fetching user data: $e');
    }
  }

  static Future<void> saveAuthData(Map<String, dynamic> authData) async {
    try {
      final storage = const FlutterSecureStorage();

      // Extract data with proper fallbacks
      final userData = authData['provider'] ?? authData['user'] ?? authData;
      final userId = userData['id'] ?? userData['_id'];
      final userType = authData['userType'] ?? 'client';

      print('Saving auth data for user: $userData');

      // Store essential auth data
      await storage.write(key: 'auth_token', value: authData['token']);
      await storage.write(key: 'userType', value: userType);
      await storage.write(key: 'userId', value: userId);
      await storage.write(key: 'isLoggedIn', value: 'true');

      // Store complete user data
      await storage.write(key: 'user_data', value: json.encode(userData));

      // Store additional provider data if applicable
      if (userType == 'service-provider') {
        await storage.write(
          key: 'businessName',
          value: userData['businessName'],
        );
        await storage.write(
          key: 'serviceType',
          value:
              userData['serviceType'] ??
              userData['serviceOffered'] ??
              'general',
        );
      }

      print('Auth Data Saved Successfully:');
      print('- Token: ${authData['token']?.substring(0, 10)}...');
      print('- UserType: $userType');
      print('- UserId: $userId');
      print('- Name: ${userData['name']}');
      if (userType == 'service-provider') {
        print('- Business Name: ${userData['businessName']}');
      }
    } catch (e) {
      print('Error saving auth data: $e');
      throw Exception('Failed to save authentication data: $e');
    }
  }

  // Add new method to verify auth state
  static Future<bool> verifyAuthState() async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final userType = await storage.read(key: 'userType');
      final isLoggedIn = await storage.read(key: 'isLoggedIn');

      print('Verifying Auth State:');
      print('- Token exists: ${token != null}');
      print('- UserType: $userType');
      print('- IsLoggedIn: $isLoggedIn');

      if (token == null || userType == null || isLoggedIn != 'true') {
        return false;
      }

      // Verify token expiration
      if (token.isNotEmpty) {
        try {
          final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
          final expiryDate = DateTime.fromMillisecondsSinceEpoch(
            decodedToken['exp'] * 1000,
          );

          // Check token validity and user type match
          final bool isValidToken = DateTime.now().isBefore(expiryDate);
          final bool isValidUserType =
              userType == 'service-provider' || userType == 'client';

          print('Token validation:');
          print('- Token valid: $isValidToken');
          print('- User type valid: $isValidUserType');

          return isValidToken && isValidUserType;
        } catch (e) {
          print('Token validation error: $e');
          return false;
        }
      }
      return false;
    } catch (e) {
      print('Auth state verification error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('auth_token');
      final userType = prefs.getString('user_type');
      final userDataString = prefs.getString('user_data');
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (!isLoggedIn) return null;

      final Map<String, dynamic> authData = {
        'token': token,
        'userType': userType,
        'isLoggedIn': isLoggedIn,
      };

      if (userDataString != null) {
        final userData = json.decode(userDataString);
        if (userType == 'provider') {
          authData['provider'] = userData;
        } else {
          authData['client'] = userData;
        }
      }

      return authData;
    } catch (e) {
      print('Error getting auth data: $e');
      return null;
    }
  }

  static Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error clearing auth data: $e');
      throw Exception('Failed to clear authentication data: $e');
    }
  }

  Future<void> _handleLoginSuccess(Map<String, dynamic> data) async {
    try {
      print('Storing login data: $data');

      // Store basic auth data
      await _storage.write(key: 'auth_token', value: data['token']);
      await _storage.write(key: 'userType', value: data['userType']);

      // Store user data
      if (data['user'] != null) {
        final user = data['user'];
        await _storage.write(key: 'userId', value: user['id']);
        await _storage.write(
          key: 'user_id',
          value: user['id'],
        ); // Store both formats
        await _storage.write(key: 'name', value: user['name']);
        await _storage.write(key: 'email', value: user['email']);

        // Store additional data based on user type
        if (data['userType'] == 'service-provider') {
          await _storage.write(
            key: 'businessName',
            value: user['businessName'],
          );
          await _storage.write(key: 'serviceType', value: user['serviceType']);
        }

        // Verify storage
        final storedId = await _storage.read(key: 'userId');
        print('Verified stored UserID: $storedId');
      }

      print('DEBUG: Stored credentials:');
      print('Token: ${data['token']}');
      print('UserType: ${data['userType']}');
      print('UserID: ${data['user']?['id']}');
    } catch (e) {
      print('Error storing credentials: $e');
      throw Exception('Failed to store login data: $e');
    }
  }

  Future<void> logout() async {
    try {
      await Future.wait([
        _storage.delete(key: 'auth_token'),
        _storage.delete(key: 'userId'),
        _storage.delete(key: 'userName'),
        _storage.delete(key: 'userId'),
        _storage.delete(key: 'userName'),
        _storage.delete(key: 'email'),
        _storage.delete(key: 'userType'),
      ]);
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Failed to logout');
    }
  }

  static Future<void> saveProviderAuthData(Map<String, dynamic> data) async {
    try {
      print('Saving provider auth data: $data');

      // Save token and userType first
      await _storage.write(key: 'auth_token', value: data['token']);
      await _storage.write(
        key: 'userType',
        value: 'service-provider',
      ); // Fixed value
      await _storage.write(
        key: 'user_type',
        value: 'service-provider',
      ); // For compatibility
      await _storage.write(key: 'isLoggedIn', value: 'true');

      // Save provider data
      if (data['provider'] != null) {
        await _storage.write(key: 'userId', value: data['provider']['id']);
        await _storage.write(
          key: 'businessName',
          value: data['provider']['businessName'],
        );
        await _storage.write(
          key: 'user_data',
          value: json.encode(data['provider']),
        );
      }

      print('Provider auth data saved successfully');
    } catch (e) {
      print('Error saving provider auth data: $e');
      throw Exception('Failed to save provider authentication data: $e');
    }
  }

  static Future<Map<String, String?>> getAuthCredentials() async {
    return {
      'token': await _storage.read(key: 'auth_token'),
      'userType': await _storage.read(key: 'userType'),
      'userId': await _storage.read(key: 'userId'),
      'businessName': await _storage.read(key: 'businessName'),
    };
  }

  Future<bool> isProvider() async {
    try {
      // Check stored user type
      final userType = await _storage.read(key: 'userType');

      // Consider both 'provider' and 'service-provider' as valid provider types
      return userType?.toLowerCase() == 'provider' ||
          userType?.toLowerCase() == 'service-provider';
    } catch (e) {
      print('Error checking provider status: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getProviderLoginUrl()),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      print('Login response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Store auth data
        await _storage.write(key: 'auth_token', value: data['token']);
        await _storage.write(key: 'userId', value: data['user']['_id']);
        await _storage.write(key: 'userType', value: 'service-provider');

        return data;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> loginProvider(
    String email,
    String password,
  ) async {
    try {
      print('Attempting provider login: $email');

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/providers/login',
        ), // Add /api/ prefix
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      print('Provider login response: ${response.statusCode}');
      print('Provider response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Store auth data
        await _storage.write(key: 'auth_token', value: data['token']);
        await _storage.write(key: 'userId', value: data['provider']['id']);
        await _storage.write(key: 'userType', value: data['userType']);
        await _storage.write(
          key: 'businessName',
          value: data['provider']['businessName'],
        );

        return data;
      }

      throw Exception('Login failed: ${response.statusCode}');
    } catch (e) {
      print('Provider login error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> loginClient(
    String email,
    String password,
  ) async {
    try {
      print('Attempting client login: $email');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/clients/login'), // Add /api/ prefix
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      print('Client login response: ${response.statusCode}');
      print('Client response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Store auth data
        await _storage.write(key: 'auth_token', value: data['token']);
        await _storage.write(key: 'userId', value: data['user']['id']);
        await _storage.write(key: 'userType', value: data['userType']);
        await _storage.write(key: 'name', value: data['user']['name']);

        return data;
      }

      throw Exception('Login failed: ${response.statusCode}');
    } catch (e) {
      print('Client login error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final updatedData = json.decode(response.body);
        // Update stored user data
        await _storage.write(
          key: 'user_data',
          value: json.encode(updatedData['user']),
        );
        return updatedData;
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      print('Profile update error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signUpClientWithEmail({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
    required Map<String, dynamic> location,
    String? profilePicture,
    required String backupContact,
    required String? preferredCommunication,
    required String? timezone,
    String? role,
  }) async {
    try {
      // Validate location format
      if (!_isValidGeoJsonPoint(location)) {
        throw FormatException('Invalid GeoJSON Point format');
      }

      final response = await _dio.post(
        '/api/clients/signup',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          'address': address,
          'location': location,
          'role': role ?? 'client',
          'backupContact': backupContact,
          'preferredCommunication': preferredCommunication,
          'timezone': timezone,
        },
      );

      return response.data;
    } catch (e) {
      print('❌ Signup error: $e');
      rethrow;
    }
  }

  bool _isValidGeoJsonPoint(Map<String, dynamic> location) {
    try {
      return location['type'] == 'Point' &&
          location['coordinates'] is List &&
          (location['coordinates'] as List).length == 2 &&
          (location['coordinates'] as List).every((e) => e is num);
    } catch (e) {
      return false;
    }
  }
}
