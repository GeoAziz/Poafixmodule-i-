import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'network_service.dart';

class ApiConfig {
  static final NetworkService _networkService = NetworkService();
  static http.Client httpClient = http.Client();
  
  // Default values
  static const String defaultLatitude = '-1.2921';
  static const String defaultLongitude = '36.8219';
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  static const String geocodingEndpoint = 'https://maps.googleapis.com/maps/api/geocode/json';
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Debug logging helper
  static void debugLog(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  /// Get the current working base URL
  static String get baseUrl {
    return _networkService.baseUrl ?? 'http://10.0.2.2:5000';
  }

  /// Get API URL with endpoint
  static String getApiUrl(String endpoint) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$base/api/$cleanEndpoint';
  }

  /// Initialize network discovery
  static Future<void> initialize() async {
    debugLog('🔄 Initializing network discovery...');
    
    final discoveredUrl = await _networkService.discoverBackendUrl();
    
    if (discoveredUrl != null) {
      debugLog('✅ Network initialization complete. Base URL: $discoveredUrl');
    } else {
      debugLog('❌ Network initialization failed. No working backend found.');
    }
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
        return '$baseUrl/api/clients/login';
      case 'provider':
        return '$baseUrl/api/providers/login';
      case 'admin':
        return '$baseUrl/api/admin/login';
      default:
        return '$baseUrl/api/auth/login';
    }
  }

  // Endpoint builders
  static String getEndpointUrl(String endpoint) {
    return getApiUrl(endpoint);
  }

  static String getClientLoginUrl() => '$baseUrl/api/clients/login';
  static String getProviderLoginUrl() => '$baseUrl/api/providers/login';
  static String getAdminLoginUrl() => '$baseUrl/api/admin/login';

  // Debug and utility methods
  static void printConnectionInfo() {
    debugLog('🔧 ApiConfig Info:');
    debugLog('📍 Base URL: $baseUrl');
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

  static const List<String> _potentialUrls = [
    'http://192.168.0.101:5000', // <-- This matches your backend!
    'http://10.0.2.2:5000',      // Emulator access to host
    'http://localhost:5000',
    'http://127.0.0.1:5000',
    // Remove or update any references to port 3000
  ];
}
