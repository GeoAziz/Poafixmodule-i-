import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

import '../core/services/payment_service.dart' as services;
import '../core/services/payment_service.dart' show PaymentHistoryItem;

class PaymentHistoryPage extends StatefulWidget {
  final String userId;

  const PaymentHistoryPage({Key? key, required this.userId}) : super(key: key);

  @override
  _PaymentHistoryPageState createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final services.PaymentService _paymentService = services.PaymentService();
  List<PaymentHistoryItem> _paymentHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    setState(() => _isLoading = true);

    try {
      final history = await _paymentService.getPaymentHistory(widget.userId);
      setState(() {
        _paymentHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load payment history')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchPaymentHistory,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPaymentHistory,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _paymentHistory.isEmpty
                ? _buildEmptyState()
                : _buildPaymentHistoryList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          SizedBox(height: 20),
          Text(
            'No Payment History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            'Your past payments will appear here',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: _paymentHistory.length,
      itemBuilder: (context, index) {
        final payment = _paymentHistory[index];
        return FadeInUp(
          delay: Duration(milliseconds: 100 * index),
          child: PaymentHistoryCard(payment: payment),
        );
      },
    );
  }
}

class PaymentHistoryCard extends StatelessWidget {
  final PaymentHistoryItem payment;

  const PaymentHistoryCard({Key? key, required this.payment}) : super(key: key);

  Color _getStatusColor() {
    switch (payment.status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking ID: ${payment.bookingId}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    payment.status,
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '\$${payment.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  payment.date.toLocal().toString().split(' ')[0],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Text(
                  payment.paymentMethod,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
