import 'package:flutter/material.dart';
import '../../services/mpesa_service.dart';
import 'package:lottie/lottie.dart';

class ServicePaymentScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final double amount;

  const ServicePaymentScreen({
    Key? key,
    required this.booking,
    required this.amount,
  }) : super(key: key);

  @override
  State<ServicePaymentScreen> createState() => _ServicePaymentScreenState();
}

class _ServicePaymentScreenState extends State<ServicePaymentScreen> {
  final _phoneController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _initiatePayment() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter phone number')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await MpesaService.initiatePayment(
        phone: _phoneController.text,
        amount: widget.amount,
        bookingId: widget.booking['_id'],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Payment initiated. Check your phone for STK push')),
      );

      // Start polling for payment status
      _pollPaymentStatus(widget.booking['_id']);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment initiation failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pollPaymentStatus(String bookingId) async {
    bool completed = false;
    int attempts = 0;

    while (!completed && attempts < 10) {
      await Future.delayed(Duration(seconds: 5));
      try {
        final status = await MpesaService.checkPaymentStatus(bookingId);
        if (status['status'] == 'completed') {
          completed = true;
          if (!mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment completed successfully')),
          );
        }
      } catch (e) {
        print('Error checking payment status: $e');
      }
      attempts++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Payment Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Amount Due',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    'KES ${widget.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Service: ${widget.booking['serviceType']}',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Payment Form
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'M-Pesa Payment',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              hintText: '254XXXXXXXXX',
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          SizedBox(height: 20),
                          _isProcessing
                              ? Center(
                                  child: Column(
                                    children: [
                                      Lottie.asset(
                                        'assets/animations/payment_processing.json',
                                        width: 200,
                                        height: 200,
                                      ),
                                      Text('Processing Payment...',
                                          style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _initiatePayment,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text('Pay with M-Pesa'),
                                ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Payment Instructions
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Instructions:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('1. Enter your M-Pesa phone number'),
                          Text('2. Click "Pay with M-Pesa"'),
                          Text('3. Wait for the STK push on your phone'),
                          Text('4. Enter your M-Pesa PIN to complete payment'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
