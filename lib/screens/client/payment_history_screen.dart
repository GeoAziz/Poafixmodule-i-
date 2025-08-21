import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentHistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> payments;
  const PaymentHistoryScreen({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment History')),
      body: payments.isEmpty
          ? Center(child: Text('No payments yet'))
          : ListView.builder(
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      payment['method'] == 'mpesa'
                          ? Icons.phone_android
                          : Icons.payment,
                      color: payment['status'] == 'completed'
                          ? Colors.green
                          : Colors.orange,
                    ),
                    title: Text(
                      'KES ${payment['amount']}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Booking: ${payment['bookingId'] ?? '--'}\nStatus: ${payment['status']}',
                    ),
                    trailing: payment['status'] == 'completed'
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : Icon(Icons.hourglass_empty, color: Colors.orange),
                  ),
                );
              },
            ),
    );
  }
}
