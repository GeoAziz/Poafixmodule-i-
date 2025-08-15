import 'package:flutter/material.dart';

class PaymentBillingScreen extends StatelessWidget {
  const PaymentBillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Payment & Billing")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text("Credit Card"),
              subtitle: Text("Visa ending in 1234"),
            ),
            ListTile(
              title: Text("Billing History"),
              subtitle: Text("Last payment: \$50"),
            ),
          ],
        ),
      ),
    );
  }
}
