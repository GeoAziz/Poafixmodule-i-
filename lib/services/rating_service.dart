import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class RatingService {
  static const _storage = FlutterSecureStorage();

  // Submit rating after service completion
  Future<Map<String, dynamic>> submitRating({
    required String bookingId,
    required String providerId,
    required double rating,
    String? review,
    Map<String, double>? categoryRatings,
    List<String>? quickFeedback,
    List<String>? images,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final userId = await _storage.read(key: 'user_id');

      final response = await http.post(
        Uri.parse('${ApiConfig.initialBaseUrl}/ratings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'bookingId': bookingId,
          'providerId': providerId,
          'clientId': userId,
          'rating': rating,
          'review': review,
          'categoryRatings': categoryRatings ?? {},
          'quickFeedback': quickFeedback ?? [],
          'images': images ?? [],
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Failed to submit rating');
    } catch (e) {
      throw Exception('Error submitting rating: $e');
    }
  }

  // Create a new rating (alternative method name for submitRating)
  Future<Map<String, dynamic>> createRating(
    Map<String, dynamic> ratingData,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final userId = await _storage.read(key: 'user_id');

      final response = await http.post(
        Uri.parse('${ApiConfig.initialBaseUrl}/ratings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'bookingId': ratingData['bookingId'],
          'providerId': ratingData['providerId'],
          'clientId': userId,
          'rating': ratingData['score'], // Map 'score' to 'rating'
          'review': ratingData['comment'],
          'serviceType': ratingData['serviceType'],
          'categoryRatings': ratingData['categoryRatings'] ?? {},
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Failed to create rating');
    } catch (e) {
      throw Exception('Error creating rating: $e');
    }
  }

  // Get provider ratings
  Future<Map<String, dynamic>> getProviderRatings(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');

      final response = await http.get(
        Uri.parse('${ApiConfig.initialBaseUrl}/ratings/provider/$providerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get ratings');
    } catch (e) {
      throw Exception('Error getting ratings: $e');
    }
  }

  // Trigger rating request after booking completion
  Future<void> triggerRatingRequest(String clientId, String bookingId) async {
    try {
      final token = await _storage.read(key: 'auth_token');

      await http.post(
        Uri.parse('${ApiConfig.initialBaseUrl}/ratings/trigger'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'clientId': clientId, 'bookingId': bookingId}),
      );
    } catch (e) {
      print('Error triggering rating request: $e');
    }
  }

  // Get rating analytics for provider
  Future<Map<String, dynamic>> getRatingAnalytics(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');

      final response = await http.get(
        Uri.parse('${ApiConfig.initialBaseUrl}/ratings/analytics/$providerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get analytics');
    } catch (e) {
      throw Exception('Error getting analytics: $e');
    }
  }
}
