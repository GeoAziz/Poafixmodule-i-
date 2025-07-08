import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class SignupHandler {
  static Future<Map<String, dynamic>> _makeSignupRequest(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    print('Making signup request to: $endpoint');
    print('Request payload: ${json.encode(data)}');

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 15));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode != 201) {
        throw Exception(responseData['error'] ?? 'Failed to create account');
      }

      return responseData;
    } catch (e) {
      print('Request error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> signupClient({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
  }) async {
    final data = {
      'name': name,
      'email': email.trim(),
      'password': password,
      'phoneNumber': phoneNumber,
      'address': address,
      'location': {
        'type': 'Point',
        'coordinates': [-1.2921, 36.8219]
      }
    };

    final response = await _makeSignupRequest('/auth/signup/client', data);

    return {
      'success': true,
      'userType': 'client',
      'token': response['token'],
      'user': response['client'] ?? response['user'],
    };
  }

  static Future<Map<String, dynamic>> signupProvider({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String businessName,
    required String businessAddress,
    required String serviceType,
  }) async {
    final signupData = {
      'name': name,
      'email': email.trim(),
      'password': password,
      'phoneNumber': phoneNumber,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'serviceOffered': serviceType.toLowerCase(),
      'userType': 'provider',
      'location': {
        'type': 'Point',
        'coordinates': [-1.2921, 36.8219]
      },
      'status': 'active'
    };

    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/provider/signup'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(signupData),
        )
        .timeout(const Duration(seconds: 15));

    final responseData = json.decode(response.body);

    if (response.statusCode != 201) {
      throw Exception(responseData['error'] ?? 'Failed to create account');
    }

    return {
      'success': true,
      'token': responseData['token'],
      'userType': 'provider',
      'user': responseData['provider'] ?? responseData['user']
    };
  }
}
