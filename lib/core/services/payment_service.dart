import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import '../../config/api_config.dart';

class PaymentService {
  final Logger _logger = Logger();

  Future<bool> processPayment({
    required String provider,
    required String bookingId,
    required String phoneNumber,
    required double amount,
  }) async {
    String endpoint;
    switch (provider.toLowerCase()) {
      case 'mpesa':
        endpoint = ApiConfig.mpesaPaymentUrl;
        break;
      case 'airtel':
        endpoint = ApiConfig.airtelPaymentUrl;
        break;
      case 'equitel':
        endpoint = ApiConfig.equitelPaymentUrl;
        break;
      case 'kcbmpesa':
        endpoint = ApiConfig.kcbMpesaPaymentUrl;
        break;
      case 'paypal':
        endpoint = ApiConfig.paypalPaymentUrl;
        break;
      default:
        throw Exception('Unknown payment provider: $provider');
    }

    try {
      final body = {'amount': amount, 'bookingId': bookingId};
      if (provider.toLowerCase() == 'paypal') {
        body['currency'] = 'USD';
        // Optionally add PayPal-specific fields, e.g. email
        // body['email'] = paypalEmail;
      } else {
        body['phoneNumber'] = phoneNumber;
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.paymentApiKey}',
        },
        body: jsonEncode(body),
      );

      _logger.i(
        'Payment request to $provider for booking $bookingId, status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success'] == true) {
          _logger.i('Payment successful for booking $bookingId');
          return true;
        } else {
          _logger.w(
            'Payment failed for booking $bookingId: ${jsonData['message']}',
          );
          return false;
        }
      } else {
        _logger.e(
          'Payment error for $provider: ${response.statusCode} ${response.body}',
        );
        throw Exception('$provider Payment Error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Payment exception for $provider: $e');
      throw Exception('$provider Payment Error: ${e.toString()}');
    }
  }
}
