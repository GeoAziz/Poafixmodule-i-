import 'package:http/http.dart' as http;
import '../services/network_service.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Payment API endpoints (replace with your actual endpoints)
  // All payment endpoints should use the backend base URL
  static String get mpesaPaymentUrl => '${baseUrl}/api/payments/mpesa/initiate';
  static String get airtelPaymentUrl =>
      '${baseUrl}/api/payments/airtel/initiate';
  static String get equitelPaymentUrl =>
      '${baseUrl}/api/payments/equitel/initiate';
  static String get kcbMpesaPaymentUrl =>
      '${baseUrl}/api/payments/kcbmpesa/initiate';
  static String get paypalPaymentUrl =>
      '${baseUrl}/api/payments/paypal/initiate';
  // Payment API key (replace with your actual key or load from env)
  static const String paymentApiKey = 'YOUR_API_KEY';
  static final NetworkService _networkService = NetworkService();

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  /// Get the current working base URL
  static String get baseUrl {
    // Always use the discovered LAN IP if available
    final url = _networkService.getBaseUrl('ApiConfig.baseUrl');
    if (url != null) {
      print('[ApiConfig.baseUrl] Using discovered baseUrl: $url');
      return url;
    }
    // If on emulator, fallback to emulator IP
    // If on physical device, never fallback to emulator IP
    print(
      '[ApiConfig.baseUrl] FATAL: baseUrl is null, fallback to emulator IP. This should not happen!',
    );
    throw Exception(
      'ApiConfig.baseUrl is null. NetworkService did not persist or load baseUrl.',
    );
  }

  /// Initialize network discovery (call this on app start)
  static Future<void> initialize() async {
    if (kDebugMode) {
      print('🔄 Initializing network discovery...');
    }

    final discoveredUrl = await _networkService.discoverBackendUrl();

    if (kDebugMode) {
      if (discoveredUrl != null) {
        print('✅ Network initialization complete. Base URL: $discoveredUrl');
      } else {
        print('❌ Network initialization failed. No working backend found.');
      }
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
      if (kDebugMode) {
        print('❌ Connection test failed: $e');
      }
      return false;
    }
  }

  // Endpoint builders
  static String getEndpointUrl(String endpoint) {
    // Remove leading slashes and ensure proper format
    endpoint = endpoint.replaceAll(RegExp(r'^/+'), '');
    if (!endpoint.startsWith('api/')) {
      endpoint = 'api/$endpoint';
    }
    final url = '$baseUrl/$endpoint';
    print('[ApiConfig.getEndpointUrl] Called with endpoint: $endpoint');
    print('[ApiConfig.getEndpointUrl] Using baseUrl: $baseUrl');
    print('[ApiConfig.getEndpointUrl] Final URL: $url');
    return url;
  }

  // Authentication endpoints
  static String getClientLoginUrl() => '$baseUrl/api/clients/login';
  static String getProviderLoginUrl() => '$baseUrl/api/providers/login';
  static String getAdminLoginUrl() => '$baseUrl/api/admin/login';

  // Debug and utility methods
  static void printConnectionInfo() {
    print('🔧 ApiConfig Info:');
    print('📍 Base URL: $baseUrl');
    print('⏱️ Timeout: ${connectionTimeout.inSeconds}s');
    print('🔄 Max retries: $maxRetries');
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
}
