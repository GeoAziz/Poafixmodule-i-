import 'package:flutter/material.dart';

class PaymentService {
  PaymentService();

  Future<bool> processMpesaPayment({
    required String bookingId,
    required String phoneNumber,
    required double amount,
  }) async {
    try {
      // Simulate API call to M-Pesa
      await Future.delayed(Duration(seconds: 2));

      // Basic validation
      if (phoneNumber.isEmpty || !phoneNumber.startsWith('+254')) {
        throw Exception('Invalid phone number');
      }

      if (amount <= 0) {
        throw Exception('Invalid amount');
      }

      // TODO: Add actual M-Pesa API integration here
      // This is just a mock implementation
      return true;
    } catch (e) {
      debugPrint('M-Pesa payment error: $e');
      return false;
    }
  }
}
