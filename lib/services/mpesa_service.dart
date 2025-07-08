import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class MpesaService {
  static Future<Map<String, dynamic>> initiatePayment({
    required String phone,
    required double amount,
    required String bookingId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/mpesa/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phoneNumber': phone,
          'amount': amount,
          'bookingId': bookingId,
          'callbackUrl': '${ApiConfig.baseUrl}/api/payments/mpesa/callback'
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Payment initiation failed');
      }
    } catch (e) {
      print('Mpesa payment error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> checkPaymentStatus(
      String bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/mpesa/status/$bookingId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'status': data['status'],
          'transactionId': data['transactionId'],
          'amount': data['amount'],
          'message': data['message'],
        };
      } else {
        throw Exception(
            'Failed to check payment status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking payment status: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> verifyPayment(
      String transactionId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/payments/mpesa/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'transactionId': transactionId}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Payment verification failed');
      }
    } catch (e) {
      print('Error verifying payment: $e');
      rethrow;
    }
  }
}
