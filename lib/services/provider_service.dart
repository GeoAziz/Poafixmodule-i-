import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProviderService {
  static final _storage = FlutterSecureStorage();
  static const String baseUrl =
      'http://10.0.2.2:5000/api'; // Android emulator localhost

  static Future<void> updateLocation(
    String providerId,
    Map<String, dynamic> location,
    bool isAvailable,
  ) async {
    try {
      final url =
          Uri.parse('${ApiConfig.baseUrl}/providers/$providerId/location');
      print('DEBUG: Sending location update to: $url');
      print('DEBUG: Request body: ${jsonEncode({
            'location': location,
            'isAvailable': isAvailable,
          })}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'location': location,
          'isAvailable': isAvailable,
        }),
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'Location update failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG: Location update error: $e');
      throw Exception('Failed to update location: $e');
    }
  }

  static Future<void> updateSimpleLocation(
      String providerId, double latitude, double longitude) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/providers/$providerId/location'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'location': {
            'type': 'Point',
            'coordinates': [longitude, latitude]
          }
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update location: ${response.body}');
      }
    } catch (e) {
      print('Error updating location: $e');
      throw e;
    }
  }

  static Future<List<Map<String, dynamic>>> getNearbyProviders({
    required double latitude,
    required double longitude,
    required String serviceType,
    required double radius,
    String? clientId,
  }) async {
    try {
      // Use the exact parameter names expected by the server
      final queryParams = {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'service': serviceType.toLowerCase(),
        'radius': radius.toString(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/providers/nearby')
          .replace(queryParameters: queryParams);

      print('DEBUG URL: $uri');

      final response = await http.get(uri);

      print('DEBUG Response Status: ${response.statusCode}');
      print('DEBUG Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
        throw Exception(data['message'] ?? 'Invalid response format');
      }

      throw Exception('Failed to load providers: ${response.statusCode}');
    } catch (e) {
      print('Provider service error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProviderProfile(String providerId) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/providers/$providerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      throw Exception('Failed to fetch provider profile');
    } catch (e) {
      print('Error fetching provider profile: $e');
      rethrow;
    }
  }

  // Add more provider-related methods
}
