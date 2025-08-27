import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final Dio _dio = Dio();
  final String baseUrl = ApiConfig.baseUrl + '/api';

  ApiService._internal() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers = {'Content-Type': 'application/json'};
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response;
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }

  Future<Response> get(String path) async {
    try {
      final response = await _dio.get(path);
      return response;
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }

  // Profile endpoints
  Future<Map<String, dynamic>> getProfile() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/profile'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to get profile');
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/profile'),
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to update profile');
  }

  // Session endpoints
  Future<void> startSession() async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/session/start'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to start session');
    }
  }

  Future<Map<String, dynamic>> getSessionStatus() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/session/status'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to get session status');
  }

  // Activity logging
  Future<void> logActivity(String action, Map<String, dynamic> details) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/activity/log'),
      headers: headers,
      body: json.encode({'action': action, 'details': details}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to log activity');
    }
  }
}
