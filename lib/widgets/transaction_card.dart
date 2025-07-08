import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionCard extends StatelessWidget {
  final String amount;
  final String date;
  final String clientName;
  final String serviceType;
  final String status;
  final String? mpesaReference;

  const TransactionCard({
    Key? key,
    required this.amount,
    required this.date,
    required this.clientName,
    required this.serviceType,
    required this.status,
    this.mpesaReference,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(date));

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          status == 'completed' ? Icons.check_circle : Icons.pending,
          color: status == 'completed' ? Colors.green : Colors.orange,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'KES ${amount}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            Text(
              status.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: status == 'completed' ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(clientName),
            Text(serviceType),
            if (mpesaReference != null) Text('Ref: $mpesaReference'),
            Text(formattedDate, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
