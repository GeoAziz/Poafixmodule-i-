import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import './auth_service.dart';

class TokenExpiredException implements Exception {
  final String message = 'Token has expired';
}

class HttpService {
  final AuthService _authService = AuthService();

  Future<http.Response> authenticatedRequest(
    String endpoint, {
    String method = 'GET',
    dynamic body,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No token found');

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      // Add debug logging
      print('Request to: $url');
      print('Request body: ${jsonEncode(body)}');

      http.Response response;
      switch (method.toUpperCase()) {
        case 'POST':
          response =
              await http.post(url, headers: headers, body: jsonEncode(body));
          break;
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method');
      }

      // Add response logging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        await _authService.deleteToken();
        throw TokenExpiredException();
      }

      if (response.statusCode >= 400) {
        throw Exception('Request failed: ${response.body}');
      }

      return response;
    } catch (e) {
      print('HTTP Service error: $e');
      rethrow;
    }
  }
}
