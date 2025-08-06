import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class ProviderService {
  static const _storage = FlutterSecureStorage();

  // Search providers with advanced filters
  static Future<Map<String, dynamic>> searchProvidersWithFilters({
    String? serviceType,
    Map<String, double>? location,
    double radius = 10,
    double? minRating,
    double? maxPrice,
    bool? availability,
    String sortBy = 'distance',
    String sortOrder = 'asc',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/providers/search'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'serviceType': serviceType,
          'location': location,
          'radius': radius,
          'minRating': minRating,
          'maxPrice': maxPrice,
          'availability': availability,
          'sortBy': sortBy,
          'sortOrder': sortOrder,
          'page': page,
          'limit': limit,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search providers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in searchProvidersWithFilters: $e');
      throw Exception('Network error: $e');
    }
  }

  // Compare provider prices for a service
  static Future<Map<String, dynamic>> compareProviderPrices({
    required String serviceType,
    Map<String, double>? location,
    double radius = 10,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/providers/compare-prices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'serviceType': serviceType,
          'location': location,
          'radius': radius,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to compare prices: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in compareProviderPrices: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get top-rated providers
  static Future<List<dynamic>> getTopRatedProviders({
    String? serviceType,
    String? location,
    double radius = 50,
    int limit = 10,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      final queryParams = <String, String>{
        if (serviceType != null) 'serviceType': serviceType,
        if (location != null) 'location': location,
        'radius': radius.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/providers/top-rated')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Failed to get top-rated providers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTopRatedProviders: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get providers available now
  static Future<List<dynamic>> getAvailableNowProviders({
    String? serviceType,
    String? location,
    double radius = 20,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      final queryParams = <String, String>{
        if (serviceType != null) 'serviceType': serviceType,
        if (location != null) 'location': location,
        'radius': radius.toString(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/providers/available-now')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Failed to get available providers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAvailableNowProviders: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get provider ratings and reviews
  static Future<Map<String, dynamic>> getProviderRatingsAndReviews(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/providers/$providerId/ratings-reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get ratings and reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getProviderRatingsAndReviews: $e');
      throw Exception('Network error: $e');
    }
  }

  // Update provider location and availability status
  static Future<Map<String, dynamic>> updateLocation(
    String providerId,
    Map<String, dynamic> location,
    bool isAvailable,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/providers/$providerId/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'location': location,
          'isAvailable': isAvailable,
          'lastUpdated': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update location: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateLocation: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get nearby providers
  static Future<List<Map<String, dynamic>>> getNearbyProviders({
    required double latitude,
    required double longitude,
    double radius = 10.0,
    String? serviceType,
    int limit = 10,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      final queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
        'limit': limit.toString(),
        if (serviceType != null) 'serviceType': serviceType,
      };
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/providers/nearby')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['providers'] ?? []);
      } else {
        throw Exception('Failed to get nearby providers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getNearbyProviders: $e');
      throw Exception('Network error: $e');
    }
  }
}
