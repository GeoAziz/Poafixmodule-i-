import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AvailabilityService {
  static final _storage = FlutterSecureStorage();

  Future<List<Map<String, dynamic>>> getProviderAvailability(
      String providerId) async {
    try {
  final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/availability/provider/[providerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> schedule = json.decode(response.body)['data'];
        return schedule.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to fetch availability schedule');
    } catch (e) {
      print('Error fetching availability: $e');
      rethrow;
    }
  }
}
