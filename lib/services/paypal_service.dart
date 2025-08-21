import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'package:logger/logger.dart';

class PaypalService {
  static final Logger _logger = Logger();
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, dynamic>> createPayment({
    required double amount,
    required String bookingId,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/paypal/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'bookingId': bookingId,
          'currency': 'USD', // PayPal typically uses USD
        }),
      );

      final data = jsonDecode(response.body);
      _logger.i('PayPal payment creation response: $data');

      // Robustly handle both top-level and nested approvalUrl
      String? approvalUrl = data['approvalUrl'];
      if (approvalUrl == null && data['data'] != null) {
        approvalUrl = data['data']['approvalUrl'];
      }
      String? paymentId = data['paymentId'];
      if (paymentId == null && data['data'] != null) {
        paymentId = data['data']['paymentId'];
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'paymentUrl': approvalUrl,
          'approvalUrl': approvalUrl, // Add approvalUrl for robust fallback
          'paymentId': paymentId,
        };
      } else {
        _logger.e('Failed to create PayPal payment: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create payment',
        };
      }
    } catch (e) {
      _logger.e('Error creating PayPal payment: $e');
      return {'success': false, 'message': 'Failed to create payment: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkPaymentStatus(
    String bookingId,
  ) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/paypal/status/$bookingId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      _logger.i('PayPal payment status response: $data');

      if (response.statusCode == 200) {
        return {'status': data['status'], 'message': data['message']};
      } else {
        _logger.e('Failed to check PayPal payment status: ${data['message']}');
        return {
          'status': 'error',
          'message': data['message'] ?? 'Failed to check payment status',
        };
      }
    } catch (e) {
      _logger.e('Error checking PayPal payment status: $e');
      return {
        'status': 'error',
        'message': 'Failed to check payment status: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> executePayment({
    required String paymentId,
    required String payerId,
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/paypal/execute'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'paymentId': paymentId, 'payerId': payerId}),
      );

      final data = jsonDecode(response.body);
      _logger.i('PayPal payment execution response: $data');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Payment completed successfully',
        };
      } else {
        _logger.e('Failed to execute PayPal payment: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to execute payment',
        };
      }
    } catch (e) {
      _logger.e('Error executing PayPal payment: $e');
      return {'success': false, 'message': 'Failed to execute payment: $e'};
    }
  }
}
