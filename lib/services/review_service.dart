import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class ReviewService {
  static const _storage = FlutterSecureStorage();

  // Submit a review
  Future<Map<String, dynamic>> submitReview({
    required String bookingId,
    required String providerId,
    required double rating,
    required String reviewText,
    List<String>? images,
    List<String>? tags,
    bool isAnonymous = false,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final userId = await _storage.read(key: 'user_id');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'bookingId': bookingId,
          'providerId': providerId,
          'clientId': userId,
          'rating': rating,
          'reviewText': reviewText,
          'images': images ?? [],
          'tags': tags ?? [],
          'isAnonymous': isAnonymous,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Failed to submit review');
    } catch (e) {
      throw Exception('Error submitting review: $e');
    }
  }

  // Get provider reviews
  Future<List<dynamic>> getProviderReviews(String providerId, {
    int page = 1,
    int limit = 20,
    String? sortBy,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (sortBy != null) 'sortBy': sortBy,
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/reviews/provider/$providerId')
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
      }
      throw Exception('Failed to get reviews');
    } catch (e) {
      throw Exception('Error getting reviews: $e');
    }
  }

  // Get review statistics
  Future<Map<String, dynamic>> getReviewStats(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reviews/provider/$providerId/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get review stats');
    } catch (e) {
      throw Exception('Error getting review stats: $e');
    }
  }

  // Get review analytics
  Future<Map<String, dynamic>> getReviewAnalytics(String providerId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/reviews/provider/$providerId/analytics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get review analytics');
    } catch (e) {
      throw Exception('Error getting review analytics: $e');
    }
  }

  // Search reviews
  Future<List<Map<String, dynamic>>> searchReviews({
    required String query,
    String? providerId,
    double? minRating,
    double? maxRating,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      final queryParams = <String, String>{
        'q': query,
        if (providerId != null) 'providerId': providerId,
        if (minRating != null) 'minRating': minRating.toString(),
        if (maxRating != null) 'maxRating': maxRating.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/reviews/search')
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
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      throw Exception('Failed to search reviews');
    } catch (e) {
      throw Exception('Error searching reviews: $e');
    }
  }

  // Like a review
  Future<void> likeReview(String reviewId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reviews/$reviewId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Error liking review: $e');
    }
  }

  // Report a review
  Future<void> reportReview(String reviewId, String reason) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reviews/$reviewId/report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );
    } catch (e) {
      throw Exception('Error reporting review: $e');
    }
  }
}
