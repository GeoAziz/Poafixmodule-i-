import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AdvancedReportingService {
  final _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> generatePerformanceReport(
    String providerId,
    String timeframe,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
                '${ApiConfig.baseUrl}/api/providers/$providerId/reports/performance')
            .replace(
          queryParameters: {'timeframe': timeframe},
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to generate performance report: ${response.body}');
      }
    } catch (e) {
      print('Error generating performance report: $e');
      return {
        'summary': {},
        'metrics': {},
        'trends': [],
      };
    }
  }

  Future<Map<String, dynamic>> generateFinancialReport(
    String providerId,
    String timeframe,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
                '${ApiConfig.baseUrl}/api/providers/$providerId/reports/financial')
            .replace(
          queryParameters: {'timeframe': timeframe},
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to generate financial report: ${response.body}');
      }
    } catch (e) {
      print('Error generating financial report: $e');
      return {
        'revenue': {},
        'expenses': {},
        'profit': {},
      };
    }
  }

  Future<Map<String, dynamic>> generateClientReport(
    String providerId,
    String timeframe,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
                '${ApiConfig.baseUrl}/api/providers/$providerId/reports/client')
            .replace(
          queryParameters: {'timeframe': timeframe},
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to generate client report: ${response.body}');
      }
    } catch (e) {
      print('Error generating client report: $e');
      return {
        'demographics': {},
        'satisfaction': {},
        'retention': {},
      };
    }
  }

  Future<Map<String, dynamic>> generateServiceAreaReport(
    String providerId,
    String timeframe,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
                '${ApiConfig.baseUrl}/api/providers/$providerId/reports/service-area')
            .replace(
          queryParameters: {'timeframe': timeframe},
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to generate service area report: ${response.body}');
      }
    } catch (e) {
      print('Error generating service area report: $e');
      return {
        'coverage': {},
        'demand': {},
        'hotspots': [],
      };
    }
  }

  Future<bool> scheduleAutomatedReport(
    String providerId,
    Map<String, dynamic> schedule,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/reports/schedule'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(schedule),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error scheduling automated report: $e');
      return false;
    }
  }
}
