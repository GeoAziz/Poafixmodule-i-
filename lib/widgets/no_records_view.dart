import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class NoRecordsView extends StatelessWidget {
  final String message;
  final String submessage;

  const NoRecordsView({
    Key? key,
    this.message = 'No transactions yet',
    this.submessage = 'Your transactions will appear here',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty_jobs.json',
            height: 200,
            repeat: true,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Text(
            submessage,
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}
