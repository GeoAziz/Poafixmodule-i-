import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProviderServiceAreaService {
  final _storage = FlutterSecureStorage();

  Future<void> updateServiceArea({
    required List<double> coordinates,
    required double radius,
  }) async {
    try {
  final token = await _storage.read(key: 'auth_token');
      final providerId = await _storage.read(key: 'userId');

      if (token == null || providerId == null) {
        throw Exception('Authentication required');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/providers/service-area'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'providerId': providerId,
          'location': {
            'type': 'Point',
            'coordinates': coordinates,
          },
          'radius': radius,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update service area');
      }
    } catch (e) {
      print('Error updating service area: $e');
      rethrow;
    }
  }
}
