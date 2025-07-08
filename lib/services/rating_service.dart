import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/rating_model.dart';
import 'auth_service.dart';

class RatingService {
  final AuthService _authService = AuthService();

  Future<Rating> createRating(Map<String, dynamic> ratingData) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ratings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(ratingData),
      );

      if (response.statusCode == 201) {
        return Rating.fromJson(json.decode(response.body)['data']);
      }
      throw Exception('Failed to create rating: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating rating: $e');
    }
  }

  Future<List<Rating>> getProviderRatings(String providerId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/ratings/provider/$providerId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Rating.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch ratings');
    } catch (e) {
      throw Exception('Error fetching ratings: $e');
    }
  }
}
