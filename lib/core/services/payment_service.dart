import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService {
  Future<bool> processMpesaPayment({
    required String bookingId,
    required String phoneNumber,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.mpesa.com/v1/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY',
        },
        body: jsonEncode({
          'amount': amount,
          'phoneNumber': phoneNumber,
          'bookingId': bookingId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['success'];
      } else {
        throw Exception('M-Pesa Payment Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('M-Pesa Payment Error: ${e.toString()}');
    }
  }

  Future<bool> processAirtelMoneyPayment({
    required String bookingId,
    required String phoneNumber,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.airtelmoney.com/v1/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY',
        },
        body: jsonEncode({
          'amount': amount,
          'phoneNumber': phoneNumber,
          'bookingId': bookingId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['success'];
      } else {
        throw Exception('Airtel Money Payment Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Airtel Money Payment Error: ${e.toString()}');
    }
  }

  Future<bool> processEquitelPayment({
    required String bookingId,
    required String phoneNumber,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.equitel.com/v1/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY',
        },
        body: jsonEncode({
          'amount': amount,
          'phoneNumber': phoneNumber,
          'bookingId': bookingId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['success'];
      } else {
        throw Exception('Equitel Payment Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Equitel Payment Error: ${e.toString()}');
    }
  }

  Future<bool> processKCBMpesaPayment({
    required String bookingId,
    required String phoneNumber,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.kcbmpesa.com/v1/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY',
        },
        body: jsonEncode({
          'amount': amount,
          'phoneNumber': phoneNumber,
          'bookingId': bookingId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['success'];
      } else {
        throw Exception('KCB M-Pesa Payment Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('KCB M-Pesa Payment Error: ${e.toString()}');
    }
  }
}
