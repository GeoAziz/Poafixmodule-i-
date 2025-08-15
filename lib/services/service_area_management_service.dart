import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ServiceAreaManagementService {
  final _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> getServiceArea(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/service-area'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch service area: ${response.body}');
      }
    } catch (e) {
      print('Error getting service area: $e');
      return {
        'center': {'lat': 0.0, 'lng': 0.0},
        'radius': 5000,
        'zones': [],
        'restrictions': [],
      };
    }
  }

  Future<bool> updateServiceArea(
    String providerId, {
    required LatLng center,
    required double radius,
    List<Map<String, dynamic>>? zones,
    List<Map<String, dynamic>>? restrictions,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.patch(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/service-area'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'center': {
            'lat': center.latitude,
            'lng': center.longitude,
          },
          'radius': radius,
          'zones': zones,
          'restrictions': restrictions,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating service area: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getServiceAreaAnalytics(
      String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/service-area/analytics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception(
            'Failed to fetch service area analytics: ${response.body}');
      }
    } catch (e) {
      print('Error getting service area analytics: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> optimizeServiceArea(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/service-area/optimize'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to optimize service area: ${response.body}');
      }
    } catch (e) {
      print('Error optimizing service area: $e');
      return {};
    }
  }
}
