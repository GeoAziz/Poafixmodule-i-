import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/services/payment_service.dart';

void main() {
  group('PaymentService', () {
    late PaymentService service;

    setUp(() {
      service = PaymentService();
    });

    test('throws on unknown provider', () async {
      expect(
        () => service.processPayment(
          provider: 'unknown',
          bookingId: 'test',
          phoneNumber: '254700000000',
          amount: 100.0,
        ),
        throwsException,
      );
    });

    // Add more tests for each provider, mocking http responses if you refactor PaymentService for DI
  });
}
