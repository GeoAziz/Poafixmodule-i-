import 'package:http/http.dart' as http;

class ApiConfig {
  // Remove /api from the end if it exists
  static const String baseUrl = 'http://10.0.2.2:5000'; // For Android emulator
  // static const String baseUrl = 'http://192.168.0.102'; // For real device
  static const String wsUrl = 'ws://192.168.0.102/ws';

  static final http.Client httpClient = http.Client();

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  static Map<String, String> getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static String getFullUrl(String endpoint) {
    return baseUrl + (endpoint.startsWith('/') ? endpoint : '/$endpoint');
  }

  static String getEndpointUrl(String endpoint) {
    // Remove any leading slashes from endpoint
    endpoint = endpoint.replaceFirst(RegExp(r'^/+'), '');
    // Ensure we have /api/ prefix
    return '$baseUrl/$endpoint';
  }

  static void debugPrint(String message) {
    print('🔧 ApiConfig: $message');
  }

  static String getWebSocketUrl() {
    // Convert http:// to ws:// or https:// to wss://
    final wsUrl = baseUrl.replaceFirst(RegExp(r'http(s)?://'), 'ws\$1://');
    return '$wsUrl/ws';
  }

  static String getNotificationsWebSocketUrl() {
    return '${getWebSocketUrl()}/notifications';
  }

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Google Maps Configuration
  static const String googleMapsApiKey =
      'AIzaSyA6akNCPdux8Eei-eZ7eoaj_ajN5eFbMz0';
  static const String geocodingEndpoint =
      'https://maps.googleapis.com/maps/api/geocode/json';

  // Default Location Configuration
  static const double defaultLatitude = -1.2921; // Default to Nairobi
  static const double defaultLongitude = 36.8219;

  // Debug and Logging Methods
  static void debugLog(String message) {
    print('🔧 ApiConfig: $message');
  }

  static void printConnectionInfo() {
    debugLog('Base URL: $baseUrl');
    debugLog('WebSocket URL: ${getWebSocketUrl()}');
    debugLog('Default timeout: ${connectionTimeout.inSeconds}s');
    debugLog('Default location: $defaultLatitude, $defaultLongitude');
    print('HTTP Client: ${httpClient.runtimeType}');
  }

  // Endpoint Construction Methods
  static String getGeocodingUrl(String address) {
    final encodedAddress = Uri.encodeComponent(address);
    return '$geocodingEndpoint?address=$encodedAddress&key=$googleMapsApiKey';
  }

  static String getLocationUrl(double lat, double lng) {
    return '$baseUrl/location?lat=$lat&lng=$lng';
  }

  static String getNotificationsUrl() {
    return getEndpointUrl('notifications');
  }

  static String getNotificationReadUrl(String id) {
    return getEndpointUrl('notifications/$id/read');
  }

  static String getNotificationsEndpoint() {
    return getEndpointUrl('notifications');
  }

  static String getNotificationReadEndpoint(String id) {
    return '$baseUrl/notifications/$id/read';
  }

  static String getBookingsUrl() {
    return '$baseUrl/bookings'; // No duplicate /api
  }

  static String getProviderBookingsUrl(String providerId) {
    return '${getBookingsUrl()}/provider/$providerId';
  }

  // Method to check connection
  static Future<bool> checkConnection() async {
    try {
      final response = await httpClient
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Connection check failed: $e');
      return false;
    }
  }

  // Add utility method to get API URLs
  static String getApiUrl(String endpoint) {
    // Remove any leading/trailing slashes
    endpoint = endpoint.trim().replaceAll(RegExp(r'^/+|/+$'), '');

    // Remove duplicate /api/ if present
    endpoint = endpoint.startsWith('api/') ? endpoint : 'api/$endpoint';

    // Ensure proper URL construction
    return '$baseUrl/$endpoint';
  }

  // Update auth endpoints
  static String getAuthUrl(String type) {
    switch (type) {
      case 'provider':
        return '$baseUrl/api/providers/login';
      case 'client':
        return '$baseUrl/api/clients/login';
      default:
        return '$baseUrl/api/auth/login';
    }
  }

  static String getProviderLoginUrl() {
    return '$baseUrl/api/providers/login';
  }

  static String getClientLoginUrl() {
    return '$baseUrl/api/clients/login';
  }
}
