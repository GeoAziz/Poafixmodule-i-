import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:flutter/foundation.dart';
// Removed unused imports
import 'network_service.dart';
import 'auth_storage.dart';

class ApiConfig {
  static String? _baseUrl;

  /// Always use LAN IP for all devices (update as needed)
  static String get baseUrl {
    final url = _baseUrl ?? 'http://192.168.0.103:5000';
    print('[ApiConfig] baseUrl accessed: $url');
    return url;
  }

  /// Dynamically determine base URL based on device type
  static Future<String> getBaseUrl() async {
    final envUrl = dotenv.dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return 'http://192.168.0.103:5000'; // <-- Set your LAN IP or ngrok URL here
  }

  static String get initialBaseUrl => baseUrl;

  /// Call this at app startup to set the base URL
  static Future<void> initBaseUrl({String envFile = ".env.development"}) async {
    await dotenv.dotenv.load(fileName: envFile);
    _baseUrl = await getBaseUrl();
    print('[ApiConfig] Initialized with baseUrl: $_baseUrl');
  }

  /// Update last active timestamp for a user (heartbeat)
  static Future<void> updateLastActive(String userId) async {
    final url = getApiUrl('clients/update-last-active');
    try {
      // Retrieve token from storage or context
      final token = await AuthStorage().getToken();
      final response = await httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: '{"userId": "$userId"}',
      );
      if (response.statusCode == 200) {
        debugLog('✅ Last active updated for user: $userId');
      } else {
        debugLog('❌ Failed to update last active: ${response.statusCode}');
      }
    } catch (e) {
      debugLog('❌ Exception updating last active: $e');
    }
  }

  static final NetworkService _networkService = NetworkService();
  static http.Client httpClient = http.Client();

  // Default values
  static const String defaultLatitude = '-1.2921';
  static const String defaultLongitude = '36.8219';
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  static const String geocodingEndpoint =
      'https://maps.googleapis.com/maps/api/geocode/json';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Debug logging helper
  static void debugLog(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  /// Get API URL with endpoint
  static String getApiUrl(String endpoint) {
    final base = initialBaseUrl.endsWith('/')
        ? initialBaseUrl.substring(0, initialBaseUrl.length - 1)
        : initialBaseUrl;
    final cleanEndpoint = endpoint.startsWith('/')
        ? endpoint.substring(1)
        : endpoint;
    return '$base/api/$cleanEndpoint';
  }

  /// Initialize dotenv and network discovery
  static Future<void> initialize({String envFile = ".env.development"}) async {
    await dotenv.dotenv.load(fileName: envFile);
    _baseUrl = await getBaseUrl();
    debugLog('🔄 Initializing network discovery...');
    debugLog('🌐 Base URL set to: $_baseUrl');
    print('[ApiConfig] initialize complete. currentBaseUrl=$_baseUrl');
  }

  /// Get network status for debugging
  static Future<Map<String, dynamic>> getNetworkStatus() async {
    return await _networkService.getNetworkInfo();
  }

  /// Refresh network connection
  static Future<void> refreshConnection() async {
    await _networkService.refreshConnection();
  }

  /// Test connection to current base URL
  static Future<bool> testConnection() async {
    try {
      final response = await _networkService.makeRequest('/api/debug');
      return response.statusCode == 200;
    } catch (e) {
      debugLog('❌ Connection test failed: $e');
      return false;
    }
  }

  // Authentication URL builders
  static String getAuthUrl(String type) {
    switch (type.toLowerCase()) {
      case 'client':
        return '${initialBaseUrl}/api/clients/login';
      case 'provider':
        return '${initialBaseUrl}/api/providers/login';
      case 'admin':
        return '${initialBaseUrl}/api/admin/login';
      default:
        return '${initialBaseUrl}/api/auth/login';
    }
  }

  // Endpoint builders
  static String getEndpointUrl(String endpoint) {
    return getApiUrl(endpoint);
  }

  static String getClientLoginUrl() => '${initialBaseUrl}/api/clients/login';
  static String getProviderLoginUrl() =>
      '${initialBaseUrl}/api/providers/login';
  static String getAdminLoginUrl() => '${initialBaseUrl}/api/admin/login';

  // Debug and utility methods
  static void printConnectionInfo() {
    debugLog('🔧 ApiConfig Info:');
    debugLog('📍 Base URL: $initialBaseUrl');
    debugLog('⏱️ Timeout: ${connectionTimeout.inSeconds}s');
    debugLog('🔄 Max retries: $maxRetries');
  }

  // Make HTTP requests through network service
  static Future<http.Response> makeRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, String>? headers,
    dynamic body,
  }) async {
    return await _networkService.makeRequest(
      endpoint.startsWith('/') ? endpoint : '/$endpoint',
      method: method,
      headers: headers,
      body: body,
    );
  }

  // Removed unused _potentialUrls field

  static String? get currentBaseUrl => _baseUrl;
}
