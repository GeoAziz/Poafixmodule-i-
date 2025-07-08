import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import '../models/service_request.dart'; // Make sure this path is correct and the file contains the ServiceRequest class

class ServiceRequestService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> createRequest({
    required String providerId,
    required String clientId,
    required String serviceType,
    required DateTime scheduledDate,
    required Map<String, dynamic> location,
    required double amount,
    String? notes,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'provider': providerId,
          'client': clientId,
          'serviceType': serviceType,
          'scheduledDate': scheduledDate.toUtc().toIso8601String(),
          'location': location,
          'notes': notes ?? '',
          'services': [
            {
              'name': serviceType,
              'quantity': 1,
              'basePrice': amount,
              'totalPrice': amount
            }
          ],
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create request: ${response.body}');
      }
    } catch (e) {
      print('Error creating service request: $e');
      rethrow;
    }
  }

  Future<void> updateRequestStatus(
      String requestId, String status, String? reason) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/api/service-requests/$requestId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': status,
          'rejectionReason': reason,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update service request status');
      }
    } catch (e) {
      print('Error updating service request status: $e');
      throw Exception('Error updating service request status: $e');
    }
  }

  Future<List<ServiceRequest>> getClientRequests(String clientId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/service-requests/client-requests/$clientId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((e) => ServiceRequest.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load client requests: ${response.body}');
      }
    } catch (e) {
      print('Error fetching client requests: $e');
      rethrow;
    }
  }
}
