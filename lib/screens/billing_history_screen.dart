import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BillingHistoryScreen extends StatefulWidget {
  const BillingHistoryScreen({Key? key}) : super(key: key);

  @override
  _BillingHistoryScreenState createState() => _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends State<BillingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<BillingRecord> _billingHistory = [
    BillingRecord(
      date: DateTime.now().subtract(const Duration(days: 1)),
      amount: 150.00,
      description: 'Monthly Subscription',
      status: 'Paid',
    ),
    // Add more sample data here
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing History'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: AnimatedList(
              initialItemCount: _billingHistory.length,
              itemBuilder: (context, index, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: _buildBillingItem(_billingHistory[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: Tween<double>(begin: 0.8, end: 1.0)
              .animate(CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOut,
              ))
              .value,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Total Spent',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${_calculateTotalSpent()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBillingItem(BillingRecord record) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(record.description),
        subtitle: Text(
          DateFormat('MMM dd, yyyy').format(record.date),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${record.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              record.status,
              style: TextStyle(
                color: record.status == 'Paid' ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalSpent() {
    return _billingHistory.fold(
        0, (previous, current) => previous + current.amount);
  }
}

class BillingRecord {
  final DateTime date;
  final double amount;
  final String description;
  final String status;

  BillingRecord({
    required this.date,
    required this.amount,
    required this.description,
    required this.status,
  });
}
