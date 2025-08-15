import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ServiceQualityService {
  final _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> getQualityMetrics(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/quality-metrics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch quality metrics: ${response.body}');
      }
    } catch (e) {
      print('Error getting quality metrics: $e');
      return {
        'overallScore': 0,
        'reliability': 0,
        'professionalism': 0,
        'communication': 0,
        'workQuality': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getQualityReviews(
      String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/quality-reviews'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to fetch quality reviews: ${response.body}');
      }
    } catch (e) {
      print('Error getting quality reviews: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getQualityImprovementSuggestions(
      String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/quality-suggestions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to fetch improvement suggestions: ${response.body}');
      }
    } catch (e) {
      print('Error getting improvement suggestions: $e');
      return {
        'suggestions': [],
        'priority': [],
        'impact': [],
      };
    }
  }

  Future<bool> submitQualityReport(
    String providerId,
    Map<String, dynamic> report,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/quality-reports'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(report),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error submitting quality report: $e');
      return false;
    }
  }
}
