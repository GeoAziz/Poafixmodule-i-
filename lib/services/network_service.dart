import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  // Updated potential URLs based on your server output
  static const List<String> _potentialUrls = [
    'http://192.168.0.101:5000', // Your current network IP (from server logs)
    'http://10.0.2.2:5000', // Android emulator
    'http://localhost:5000', // Desktop/web
    'http://127.0.0.1:5000', // Local fallback
    'http://192.168.1.101:5000', // Common router ranges
    'http://192.168.1.100:5000',
    'http://192.168.0.100:5000',
    'http://192.168.0.102:5000',
  ];

  String? _workingBaseUrl;
  List<ConnectivityResult>? _lastConnectivity;

  // Force use of the correct backend IP for all API calls
  String? get baseUrl => 'http://192.168.0.101:5000';

  /// Test if a specific URL is reachable
  Future<bool> testUrl(String url) async {
    try {
      if (kDebugMode) {
        print('🔄 Testing URL: $url');
      }

      final response = await http.get(
        Uri.parse('$url/api/debug'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 8)); // Increased timeout for network requests

      if (kDebugMode) {
        print('📡 Response from $url: ${response.statusCode}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('❌ URL test failed for $url: $e');
      }
      return false;
    }
  }

  /// Discover which backend URL is working
  Future<String?> discoverBackendUrl() async {
    if (kDebugMode) {
      print('🔍 Starting backend URL discovery...');
    }

    // Check network connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    _lastConnectivity = connectivityResult;

    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (kDebugMode) {
        print('❌ No network connectivity detected');
      }
      return null;
    }

    if (kDebugMode) {
      print('🌐 Network type: ${connectivityResult.join(", ")}');
    }

    // Test each URL in order of preference
    for (final url in _potentialUrls) {
      if (kDebugMode) {
        print('🧪 Testing: $url');
      }

      if (await testUrl(url)) {
        _workingBaseUrl = url;
        if (kDebugMode) {
          print('✅ Found working backend: $url');
        }

        // Test authentication endpoints to ensure they work
        if (await _testAuthEndpoints(url)) {
          if (kDebugMode) {
            print('✅ Authentication endpoints verified for: $url');
          }
          return url;
        }
      }
    }

    if (kDebugMode) {
      print('❌ No working backend URL found');
    }
    return null;
  }

  /// Test authentication endpoints specifically
  Future<bool> _testAuthEndpoints(String baseUrl) async {
    final endpoints = [
      '/api/clients/login',
      '/api/providers/login',
      '/api/admin/login',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl$endpoint'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'email': 'test', 'password': 'test'}),
            )
            .timeout(Duration(seconds: 5));

        // We expect 400 or 401, not 404 (which means endpoint doesn't exist)
        if (response.statusCode != 404) {
          if (kDebugMode) {
            print(
                '✅ Auth endpoint $endpoint exists (status: ${response.statusCode})');
          }
          return true;
        }
      } catch (e) {
        // Network errors are okay, 404s are not
        continue;
      }
    }

    if (kDebugMode) {
      print('❌ No valid auth endpoints found for $baseUrl');
    }
    return false;
  }

  /// Get current connectivity status
  Future<List<ConnectivityResult>> getConnectivityStatus() async {
    return await Connectivity().checkConnectivity();
  }

  /// Get network information for debugging
  Future<Map<String, dynamic>> getNetworkInfo() async {
    final connectivity = await getConnectivityStatus();

    return {
      'connectivity': connectivity.map((e) => e.toString()).toList(),
      'workingUrl': _workingBaseUrl,
      'lastTested': DateTime.now().toIso8601String(),
      'testedUrls': _potentialUrls,
      'platform': Platform.operatingSystem,
      'isPhysicalDevice': !kIsWeb && (Platform.isAndroid || Platform.isIOS),
    };
  }

  /// Force refresh connection
  Future<String?> refreshConnection() async {
    _workingBaseUrl = null;
    return await discoverBackendUrl();
  }

  /// Make HTTP request with automatic retry
  Future<http.Response> makeRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, String>? headers,
    dynamic body,
  }) async {
    // Ensure we have a working URL
    if (_workingBaseUrl == null) {
      await discoverBackendUrl();
    }

    if (_workingBaseUrl == null) {
      throw Exception(
          'No backend server available. Please check your network connection.');
    }

    final url = Uri.parse('$_workingBaseUrl$endpoint');
    final requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    if (kDebugMode) {
      print('🚀 Making $method request to: $url');
    }

    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(url, headers: requestHeaders)
              .timeout(Duration(seconds: 30));
          break;
        case 'POST':
          response = await http
              .post(
                url,
                headers: requestHeaders,
                body: body is String ? body : json.encode(body),
              )
              .timeout(Duration(seconds: 30));
          break;
        case 'PUT':
          response = await http
              .put(
                url,
                headers: requestHeaders,
                body: body is String ? body : json.encode(body),
              )
              .timeout(Duration(seconds: 30));
          break;
        case 'DELETE':
          response = await http
              .delete(url, headers: requestHeaders)
              .timeout(Duration(seconds: 30));
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      if (kDebugMode) {
        print('📡 Response status: ${response.statusCode}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Request failed: $e');
      }

      // Try to refresh connection and retry once
      if (_workingBaseUrl != null) {
        _workingBaseUrl = null;
        await discoverBackendUrl();

        if (_workingBaseUrl != null) {
          return makeRequest(endpoint,
              method: method, headers: headers, body: body);
        }
      }

      throw Exception('Network request failed: $e');
    }
  }
}
