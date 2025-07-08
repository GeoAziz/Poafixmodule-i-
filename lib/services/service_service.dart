import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/service.dart';
import '../config/api_config.dart';
import '../services/auth_storage.dart';

class ServiceService {
  final AuthStorage _authStorage = AuthStorage();

  Future<List<Service>> getProviderServices() async {
    try {
      final credentials = await _authStorage.getCredentials();
      final token = credentials['auth_token'];
      final providerId = credentials['user_id'];

      if (token == null || providerId == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/services/provider/$providerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((json) => Service.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load services');
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  Future<void> createService(Map<String, dynamic> serviceData) async {
    try {
      final credentials = await _authStorage.getCredentials();
      final token = credentials['auth_token'];
      final providerId = credentials['user_id'];

      if (token == null || providerId == null) {
        throw Exception('Not authenticated');
      }

      // Add provider ID to service data
      serviceData['providerId'] = providerId;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/services'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              token.startsWith('Bearer ') ? token : 'Bearer $token',
        },
        body: json.encode(serviceData),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create service: ${response.body}');
      }
    } catch (e) {
      print('Error creating service: $e');
      rethrow;
    }
  }

  Future<void> updateService(Map<String, dynamic> serviceData) async {
    try {
      final credentials = await _authStorage.getCredentials();
      final token = credentials['auth_token'];
      final providerId = credentials['user_id'];

      if (token == null || providerId == null) {
        throw Exception('Not authenticated');
      }

      if (serviceData['id'] == null) {
        throw Exception('Service ID is required for update');
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/services/${serviceData['id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              token.startsWith('Bearer ') ? token : 'Bearer $token',
        },
        body: json.encode(serviceData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update service: ${response.body}');
      }
    } catch (e) {
      print('Error updating service: $e');
      rethrow;
    }
  }
}
