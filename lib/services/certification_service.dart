import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CertificationService {
  static final _storage = FlutterSecureStorage();

  Future<List<Map<String, dynamic>>> getProviderCertifications(
      String providerId) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/certifications/provider/[providerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> certs = json.decode(response.body)['data'];
        return certs.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to fetch certifications');
    } catch (e) {
      print('Error fetching certifications: $e');
      rethrow;
    }
  }
}
