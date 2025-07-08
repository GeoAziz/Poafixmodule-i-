import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/booking_provider.dart';
import '../core/services/payment_service.dart';
import '../core/models/booking_model.dart';

enum PaymentMethod {
  mpesa,
  airtelMoney,
  equitel,
  kcbMpesa,
}

class PaymentPage extends StatefulWidget {
  final BookingModel booking;

  const PaymentPage({Key? key, required this.booking}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneNumberController = TextEditingController();

  final PaymentService _paymentService = PaymentService();

  bool _isProcessing = false;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.mpesa;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Call the generic payment processing function
      await _processPaymentMethod();
    } catch (e) {
      _handlePaymentError(e);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processPaymentMethod() async {
    final phoneNumber = _phoneNumberController.text.trim();
    if (phoneNumber.isEmpty) {
      throw 'Please enter your phone number';
    }

    bool paymentResult = false;

    switch (_selectedPaymentMethod) {
      case PaymentMethod.mpesa:
        paymentResult = await _paymentService.processMpesaPayment(
          bookingId: widget.booking.id,
          phoneNumber: phoneNumber,
          amount: widget.booking.totalPrice,
        );
        break;
      case PaymentMethod.airtelMoney:
        paymentResult = await _paymentService.processAirtelMoneyPayment(
          bookingId: widget.booking.id,
          phoneNumber: phoneNumber,
          amount: widget.booking.totalPrice,
        );
        break;
      case PaymentMethod.equitel:
        paymentResult = await _paymentService.processEquitelPayment(
          bookingId: widget.booking.id,
          phoneNumber: phoneNumber,
          amount: widget.booking.totalPrice,
        );
        break;
      case PaymentMethod.kcbMpesa:
        paymentResult = await _paymentService.processKCBMpesaPayment(
          bookingId: widget.booking.id,
          phoneNumber: phoneNumber,
          amount: widget.booking.totalPrice,
        );
        break;
    }

    _handlePaymentResult(paymentResult);
  }

  void _handlePaymentResult(bool paymentResult) {
    if (paymentResult) {
      Provider.of<BookingProvider>(context, listen: false)
          .updateBookingStatus(widget.booking.id, 'paid');
      _showPaymentSuccessDialog();
    } else {
      _showPaymentFailureDialog();
    }
  }

  void _handlePaymentError(dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${error.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 60,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Payment Successful',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Your booking has been confirmed and paid.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentFailureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 60,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Payment Failed',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Unable to process your payment. Please try again.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetPaymentForm();
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _resetPaymentForm() {
    _phoneNumberController.clear();
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
      return 'Invalid phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment for Booking'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBookingDetailsCard(),
              SizedBox(height: 20),
              _buildPaymentMethodDropdown(),
              SizedBox(height: 20),
              _buildPhoneNumberField(),
              SizedBox(height: 20),
              _buildPayButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 10),
            Text('Service: ${widget.booking.serviceType}'),
            Text('Date: ${widget.booking.date}'),
            Text(
              'Total Price: \$${widget.booking.totalPrice}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 10),
        DropdownButton<PaymentMethod>(
          value: _selectedPaymentMethod,
          onChanged: (PaymentMethod? newMethod) {
            setState(() {
              _selectedPaymentMethod = newMethod!;
            });
          },
          items: PaymentMethod.values.map((PaymentMethod method) {
            return DropdownMenuItem<PaymentMethod>(
              value: method,
              child: Text(_getPaymentMethodName(method)),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.airtelMoney:
        return 'Airtel Money';
      case PaymentMethod.equitel:
        return 'Equitel';
      case PaymentMethod.kcbMpesa:
        return 'KCB M-Pesa';
    }
  }

  Widget _buildPhoneNumberField() {
    return TextFormField(
      controller: _phoneNumberController,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        hintText: '+254712345678',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.phone,
      validator: _validatePhoneNumber,
    );
  }

  Widget _buildPayButton() {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _processPayment,
      child: _isProcessing
          ? CircularProgressIndicator()
          : Text('Pay \$${widget.booking.totalPrice}'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }
}
