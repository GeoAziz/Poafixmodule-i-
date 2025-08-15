import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ClientRelationshipService {
  final _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> getClientInsights(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/client-insights'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch client insights: ${response.body}');
      }
    } catch (e) {
      print('Error getting client insights: $e');
      return {
        'regularClients': [],
        'clientSegments': [],
        'satisfaction': {},
      };
    }
  }

  Future<List<Map<String, dynamic>>> getClientFeedback(
      String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/client-feedback'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to fetch client feedback: ${response.body}');
      }
    } catch (e) {
      print('Error getting client feedback: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getClientRetentionMetrics(
      String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/retention-metrics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch retention metrics: ${response.body}');
      }
    } catch (e) {
      print('Error getting retention metrics: $e');
      return {
        'retentionRate': 0,
        'churnRate': 0,
        'repeatBookings': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getClientEngagementOpportunities(
      String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/engagement-opportunities'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception(
            'Failed to fetch engagement opportunities: ${response.body}');
      }
    } catch (e) {
      print('Error getting engagement opportunities: $e');
      return [];
    }
  }
}
