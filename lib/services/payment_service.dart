import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PaymentService {
  final _storage = const FlutterSecureStorage();
  // Remove static baseUrl. Always use ApiConfig.baseUrl dynamically.

  // Initiate MPesa payment
  Future<Map<String, dynamic>> initiateMpesaPayment({
    required String phoneNumber,
    required double amount,
    required String bookingId,
    required String clientId,
    required String providerId,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/mpesa/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'amount': amount,
          'bookingId': bookingId,
          'clientId': clientId,
          'providerId': providerId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to initiate MPesa payment: ${response.body}');
      }
    } catch (e) {
      print('Error initiating MPesa payment: $e');
      rethrow;
    }
  }

  // Initiate PayPal payment
  Future<Map<String, dynamic>> initiatePaypalPayment({
    required double amount,
    required String bookingId,
    required String clientId,
    required String providerId,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/paypal/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'bookingId': bookingId,
          'clientId': clientId,
          'providerId': providerId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to initiate PayPal payment: ${response.body}');
      }
    } catch (e) {
      print('Error initiating PayPal payment: $e');
      rethrow;
    }
  }

  // Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus(String bookingId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/status/$bookingId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check payment status: ${response.body}');
      }
    } catch (e) {
      print('Error checking payment status: $e');
      rethrow;
    }
  }

  // Get pending payments for a client
  Future<List<Map<String, dynamic>>> getPendingPayments(String clientId) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) throw Exception('Authentication token not found');
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/payments/paypal/pending/$clientId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['payments'] ?? []);
    } else {
      throw Exception('Failed to fetch pending payments');
    }
  }

  Future<String> getPaypalApprovalUrl(
    String paymentId,
    dynamic amount,
    String bookingId,
    String client,
    String provider,
  ) async {
    // TODO: Implement backend call to get PayPal approval URL
    // Example:
    // final response = await http.post(
    //   Uri.parse('https://your-backend/paypal/create-payment'),
    //   body: json.encode({
    //     'paymentId': paymentId,
    //     'amount': amount,
    //     'bookingId': bookingId,
    //     'client': client,
    //     'provider': provider,
    //   }),
    //   headers: {'Content-Type': 'application/json'},
    // );
    // if (response.statusCode == 200) {
    //   final data = json.decode(response.body);
    //   return data['approvalUrl'] as String;
    // }
    // return '';
    throw UnimplementedError('getPaypalApprovalUrl not implemented');
  }
}
