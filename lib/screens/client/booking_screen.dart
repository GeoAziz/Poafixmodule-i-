import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/payment_service.dart';
import '../../services/notification_service.dart';
import '../../services/user_status_service.dart';
import '../payment/mpesa_payment_screen.dart';
import '../payment/paypal_payment_screen.dart';
import '../../models/booking.dart';

class ClientBookingsScreen extends StatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  State<ClientBookingsScreen> createState() => _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends State<ClientBookingsScreen> {
  List<Map<String, dynamic>> _pendingPayments = [];
  bool _loadingPayments = false;
  String? _error;
  String clientId = '';
  NotificationService? _notificationService;
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _fetchClientIdAndPayments();
    _setupSocketListener();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  void _setupSocketListener() async {
    await _notificationService?.connectWebSocket();
    _socketSubscription = _notificationService?.socketStream?.listen((event) {
      final data = event is String ? event : event.toString();
      if (data.contains('PAYMENT_REQUEST')) {
        // Payment request received, refresh payments
        _fetchClientIdAndPayments();
        // Optionally show a prompt
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New payment request received!')),
        );
      }
      if (data.contains('PAYMENT_COMPLETED')) {
        // Payment completed, refresh payments
        _fetchClientIdAndPayments();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment completed!')));
      }
    });
  }

  Future<void> _fetchClientIdAndPayments() async {
    // TODO: Replace with actual client ID fetch logic
    // For demo, hardcoded or fetch from secure storage/profile
    setState(() {
      _loadingPayments = true;
    });
    try {
      clientId = await _getClientId();
      _pendingPayments = await PaymentService().getPendingPayments(clientId);
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _loadingPayments = false;
      });
    }
  }

  Future<String> _getClientId() async {
    // Replace with actual logic to get logged-in client ID
    // e.g., from secure storage or profile provider
    return '689dda4e522262694e34d873';
  }

  void _promptPayment(Map<String, dynamic> payment) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => PaymentPromptSheet(payment: payment),
    );
  }

  void _showBookingDetails(Map<String, dynamic> booking) async {
    Map<String, dynamic>? providerStatus;
    if (booking['providerId'] != null) {
      providerStatus = await UserStatusService.fetchUserStatus(
        booking['providerId'],
      );
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Service: ${booking['serviceType']}'),
              Text('Status: ${booking['status']}'),
              Text('Date: ${booking['schedule']}'),
              Text('Amount: ${booking['amount'] ?? '--'}'),
              if (providerStatus != null) ...[
                Text(
                  'Provider Online: ${providerStatus['isOnline'] == true ? 'Online' : 'Offline'}',
                ),
                Text(
                  'Provider Last Active: ${providerStatus['lastActive'] != null ? DateTime.parse(providerStatus['lastActive']).toLocal().toString() : 'Unknown'}',
                ),
              ],
              Text('Description: ${booking['description'] ?? ''}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Bookings')),
      body: _loadingPayments
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
          : ListView(
              children: [
                ..._pendingPayments.map(
                  (payment) => ListTile(
                    title: Text('Payment Pending: ${payment['amount']}'),
                    subtitle: Text('Booking: ${payment['bookingId']}'),
                    trailing: ElevatedButton(
                      child: Text('Pay Now'),
                      onPressed: () => _promptPayment(payment),
                    ),
                    onTap: () => _showBookingDetails(payment),
                  ),
                ),
              ],
            ),
    );
  }
}

class PaymentPromptSheet extends StatelessWidget {
  final Map<String, dynamic> payment;
  const PaymentPromptSheet({required this.payment, super.key});

  Booking _mapToBooking(Map<String, dynamic> payment) {
    // Map payment to Booking model for payment screens
    return Booking(
      id: payment['bookingId'] ?? '',
      amount: (payment['amount'] ?? 0).toDouble(),
      serviceType: payment['serviceType'] ?? '',
      scheduledDate: payment['scheduledDate'] ?? '',
      status: payment['status'] ?? '',
      payment: payment['payment'] ?? '',
      services: payment['services'] ?? [],
      client: payment['client'] ?? '',
      provider: payment['provider'] ?? '',
      notes: payment['notes'] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = _mapToBooking(payment);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(title: Text('Choose Payment Method')),
        Divider(),
        ListTile(
          leading: Icon(Icons.phone_android, color: Colors.green),
          title: Text('Mpesa', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Pay securely via mobile money'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => MpesaPaymentScreen(booking: booking),
              ),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.payment, color: Colors.blue),
          title: Text('PayPal', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Pay with your PayPal account'),
          onTap: () async {
            Navigator.pop(context);
            String approvalUrl;
            try {
              approvalUrl = await PaymentService().getPaypalApprovalUrl(
                payment['paymentId'] ?? '',
                payment['amount'],
                payment['bookingId'] ?? '',
                payment['client'] ?? '',
                payment['provider'] ?? '',
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to get PayPal approval URL: $e'),
                ),
              );
              return;
            }
            if (approvalUrl.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PayPal approval URL not available')),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => PaypalPaymentScreen(
                  approvalUrl: approvalUrl,
                  bookingId: payment['bookingId'] ?? '',
                  amount: payment['amount'] ?? 0,
                  paymentId: payment['paymentId'] ?? '',
                ),
              ),
            );
          },
        ),
        Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Your payment is secure and encrypted.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
