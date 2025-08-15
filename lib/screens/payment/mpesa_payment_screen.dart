import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/booking.dart';
import '../../services/mpesa_service.dart';
import 'package:lottie/lottie.dart';
import 'package:logger/logger.dart';

class MpesaPaymentScreen extends StatefulWidget {
  final Booking booking;

  const MpesaPaymentScreen({super.key, required this.booking});

  @override
  State<MpesaPaymentScreen> createState() => _MpesaPaymentScreenState();
}

class _MpesaPaymentScreenState extends State<MpesaPaymentScreen> {
  final _phoneController = TextEditingController();
  final Logger _logger = Logger();
  bool _isLoading = false;
  String _paymentStatus = '';
  Timer? _statusCheckTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _paymentStatus = 'Initiating payment...';
    });

    try {
      final response = await MpesaService.initiatePayment(
        phone: _phoneController.text,
        amount: widget.booking.amount,
        bookingId: widget.booking.id,
      );

      if (!mounted) return;

      _logger.i('Payment initiated for booking ${widget.booking.id}');
      setState(() {
        _paymentStatus =
            'Payment initiated. Check your phone for the STK push.';
      });

      // Start checking payment status
      _startStatusCheck();
    } catch (e) {
      if (!mounted) return;
      _logger.e('Payment initiation failed: $e');
      setState(() {
        _paymentStatus = 'Payment failed: $e';
        _isLoading = false;
      });
    }
  }

  void _startStatusCheck() {
    _statusCheckTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final status = await MpesaService.checkPaymentStatus(widget.booking.id);

        if (!mounted) return;

        _logger.i(
            'Payment status for booking ${widget.booking.id}: ${status['status']}');
        setState(() => _paymentStatus = status['status']);

        if (status['status'] == 'completed') {
          timer.cancel();
          _logger.i('Payment completed for booking ${widget.booking.id}');
          _showPaymentSuccess();
          // TODO: Trigger booking/job status refresh here
        } else if (status['status'] == 'failed') {
          timer.cancel();
          _logger.w('Payment failed for booking ${widget.booking.id}');
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment failed. Please try again.')),
          );
        }
      } catch (e) {
        _logger.e('Error checking payment status: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking payment status: $e')),
        );
      }
    });
  }

  void _showPaymentSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/payment_success.json',
              width: 200,
              height: 200,
            ),
            const Text('Thank you for your payment!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MPESA Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount: KES ${widget.booking.amount}',
                        style: Theme.of(context).textTheme.titleLarge),
                    Text('Service: ${widget.booking.serviceType}'),
                    Text('Provider: ${widget.booking.provider}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'MPESA Phone Number',
                hintText: 'Enter your MPESA number (254...)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            if (_paymentStatus.isNotEmpty)
              Text(_paymentStatus,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _initiatePayment,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }
}
