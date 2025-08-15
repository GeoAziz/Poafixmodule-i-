import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class DynamicPricingService {
  final _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> calculateDynamicPrice({
    required String serviceId,
    required double basePrice,
    required String location,
    DateTime? scheduledTime,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/pricing/calculate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'serviceId': serviceId,
          'basePrice': basePrice,
          'location': location,
          'scheduledTime': scheduledTime?.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to calculate dynamic price: ${response.body}');
      }
    } catch (e) {
      print('Error calculating dynamic price: $e');
      return {
        'finalPrice': basePrice,
        'multiplier': 1.0,
        'factors': {
          'demand': 1.0,
          'time': 1.0,
          'location': 1.0,
        },
      };
    }
  }

  Future<Map<String, dynamic>> getDemandMetrics(String location) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/pricing/demand-metrics').replace(
          queryParameters: {'location': location},
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch demand metrics: ${response.body}');
      }
    } catch (e) {
      print('Error getting demand metrics: $e');
      return {
        'currentDemand': 'Low',
        'forecastedDemand': 'Medium',
        'suggestedMultiplier': 1.0,
      };
    }
  }

  Future<Map<String, dynamic>> getPriceHistory(String serviceId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/pricing/history/$serviceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch price history: ${response.body}');
      }
    } catch (e) {
      print('Error getting price history: $e');
      return {
        'history': [],
        'averagePrice': 0,
        'priceRange': {'min': 0, 'max': 0},
      };
    }
  }

  Future<bool> updateBasePrice(String serviceId, double newBasePrice) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/pricing/base-price/$serviceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'basePrice': newBasePrice}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating base price: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getPriceRecommendations(String serviceId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/pricing/recommendations/$serviceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to fetch price recommendations: ${response.body}');
      }
    } catch (e) {
      print('Error getting price recommendations: $e');
      return {
        'recommendedBasePrice': 0,
        'competitorPrices': {'min': 0, 'max': 0, 'average': 0},
        'demandTrends': [],
      };
    }
  }
}
