import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ReviewService {
  static final _storage = FlutterSecureStorage();

  Future<void> submitReview({
    required String providerId,
    required String bookingId,
    required double rating,
    required String review,
  }) async {
    final token = await _storage.read(key: 'token') ??
        await _storage.read(key: 'auth_token');
    if (token == null) throw Exception('No auth token found');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/reviews'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'providerId': providerId,
        'bookingId': bookingId,
        'rating': rating,
        'review': review,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to submit review: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getProviderReviews(
      String providerId) async {
    final token = await _storage.read(key: 'token') ??
        await _storage.read(key: 'auth_token');
    if (token == null) throw Exception('No auth token found');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/reviews/provider/$providerId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> reviews = json.decode(response.body)['data'];
      return reviews.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch reviews');
  }
}
