import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'auth_storage.dart';

class ServiceService {
  final AuthStorage _authStorage = AuthStorage();

  Future<List<Map<String, dynamic>>> getProviderServices() async {
    try {
      final credentials = await _authStorage.getCredentials();
      final token = credentials['auth_token'];
      final providerId = credentials['user_id'];
      if (token == null || providerId == null) {
        throw Exception('Not authenticated');
      }
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/providers/$providerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to load provider services: ${response.statusCode} ${response.body}');
      }
      final data = json.decode(response.body);
      List offered = [];
      if (data is Map && data.containsKey('data')) {
        offered = data['data']['serviceOffered'] ?? [];
      } else if (data is Map && data.containsKey('serviceOffered')) {
        offered = data['serviceOffered'] ?? [];
      }
      return List<Map<String, dynamic>>.from(offered);
    } catch (e) {
      debugPrint('Error fetching provider services: $e');
      rethrow;
    }
  }

  Future<void> updateProviderServices(
      List<Map<String, dynamic>> services) async {
    final credentials = await _authStorage.getCredentials();
    final token = credentials['auth_token'];
    final providerId = credentials['user_id'];
    if (token == null || providerId == null) {
      throw Exception('Not authenticated');
    }
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/providers/$providerId/services'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'serviceOffered': services}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update services: ${response.body}');
    }
  }
}
