import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AutomatedSchedulingService {
  final _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> getAvailabilitySchedule(
      String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/providers/$providerId/schedule'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch schedule: ${response.body}');
      }
    } catch (e) {
      print('Error getting schedule: $e');
      return {
        'regularHours': [],
        'exceptions': [],
        'breaks': [],
      };
    }
  }

  Future<bool> updateAvailabilitySchedule(
    String providerId,
    Map<String, dynamic> schedule,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/providers/$providerId/schedule'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(schedule),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating schedule: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> optimizeSchedule(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/schedule/optimize'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to optimize schedule: ${response.body}');
      }
    } catch (e) {
      print('Error optimizing schedule: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getBookingRecommendations(
      String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/recommendations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to fetch recommendations: ${response.body}');
      }
    } catch (e) {
      print('Error getting recommendations: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getScheduleAnalytics(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/schedule/analytics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch schedule analytics: ${response.body}');
      }
    } catch (e) {
      print('Error getting schedule analytics: $e');
      return {
        'utilizationRate': 0,
        'peakHours': [],
        'downtimes': [],
      };
    }
  }
}
