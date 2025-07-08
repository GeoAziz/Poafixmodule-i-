import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

class ProviderLocationService {
  final _storage = const FlutterSecureStorage();
  int _retryAttempts = 0;
  static const _maxRetries = 3;
  static const _timeout = Duration(seconds: 20); // Increased timeout
  static const String baseUrl = 'http://192.168.0.102/api'; // Corrected IP

  Future<void> updateLocation({
    required String providerId,
    required double latitude,
    required double longitude,
    required bool isAvailable,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Authentication token not found');

      final url = Uri.parse('$baseUrl/providers/$providerId/update-location');

      print('\n=== Location Update Request ===');
      print('DEBUG: Sending location update to: $url');
      final payload = {
        'location': {
          'type': 'Point',
          'coordinates': [longitude, latitude]
        },
        'isAvailable': isAvailable
      };
      print('DEBUG: Request body: ${jsonEncode(payload)}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'Location update failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG: Location update error: $e');
      rethrow;
    }
  }

  Future<bool> checkProviderStatus(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return false;

      final url = Uri.parse('$baseUrl/providers/$providerId/status');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(_timeout);

      return response.statusCode == 200 &&
          json.decode(response.body)['isAvailable'] == true;
    } catch (e) {
      print('Error checking status: $e');
      return false;
    }
  }

  Future<Position> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      );
      return position;
    } catch (e) {
      print('Get location error: $e');
      throw Exception('Failed to get current location: $e');
    }
  }
}
