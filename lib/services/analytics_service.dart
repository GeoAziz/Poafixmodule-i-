import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AnalyticsService {
  final _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> getProviderAnalytics(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/providers/$providerId/analytics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch analytics: ${response.body}');
      }
    } catch (e) {
      print('Error getting analytics: $e');
      return {
        'monthlyEarnings': 0,
        'pendingEarnings': 0,
        'completedJobs': 0,
        'rating': 0.0,
        'totalReviews': 0,
        'earningsData': [
          {'x': 0, 'y': 0},
          {'x': 1, 'y': 0},
          {'x': 2, 'y': 0},
          {'x': 3, 'y': 0},
          {'x': 4, 'y': 0},
          {'x': 5, 'y': 0},
          {'x': 6, 'y': 0},
        ],
        'monthlyTarget': 10000,
      };
    }
  }

  Future<Map<String, dynamic>> getServiceAreaMetrics(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/service-area-metrics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to fetch service area metrics: ${response.body}');
      }
    } catch (e) {
      print('Error getting service area metrics: $e');
      return {
        'totalArea': 0,
        'popularLocations': [],
        'coverage': 0,
      };
    }
  }

  Future<Map<String, dynamic>> getBookingAnalytics(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/booking-analytics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch booking analytics: ${response.body}');
      }
    } catch (e) {
      print('Error getting booking analytics: $e');
      return {
        'totalBookings': 0,
        'completionRate': 0,
        'averageResponseTime': 0,
        'bookingTrends': [],
      };
    }
  }

  Future<Map<String, dynamic>> getDynamicPricingMetrics(
      String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/pricing-metrics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch pricing metrics: ${response.body}');
      }
    } catch (e) {
      print('Error getting pricing metrics: $e');
      return {
        'baseRate': 0,
        'demandMultiplier': 1.0,
        'peakHours': [],
        'priceHistory': [],
      };
    }
  }

  Future<Map<String, dynamic>> getPerformanceMetrics(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/providers/$providerId/performance-metrics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to fetch performance metrics: ${response.body}');
      }
    } catch (e) {
      print('Error getting performance metrics: $e');
      return {
        'responseRate': 0,
        'completionRate': 0,
        'onTimeRate': 0,
        'customerSatisfaction': 0,
        'qualityScore': 0,
      };
    }
  }
}
