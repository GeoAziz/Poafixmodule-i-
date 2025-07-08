// terms_and_conditions_screen.dart
import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms and Conditions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms and Conditions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                '1. Acceptance of Terms\n\n'
                'By using our services, you agree to the following terms and conditions. Please read them carefully.\n\n'
                '2. Service Description\n\n'
                'We provide services in various fields such as cleaning, plumbing, etc. Details of the services are available on our platform.\n\n'
                '3. Payment\n\n'
                'Payment for services should be made according to the pricing mentioned on the platform.\n\n'
                '4. Cancellation Policy\n\n'
                'You may cancel any scheduled services within 24 hours prior to the scheduled time without any penalty.\n\n'
                '5. Liability\n\n'
                'We are not liable for any damages or losses caused by our services, except as outlined in our policies.\n\n'
                '6. Privacy\n\n'
                'We respect your privacy and handle your data according to our privacy policy.\n\n'
                '7. Modifications\n\n'
                'We may modify these terms from time to time. You are responsible for checking for updates.\n\n'
                'For more details, please contact our support team.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
