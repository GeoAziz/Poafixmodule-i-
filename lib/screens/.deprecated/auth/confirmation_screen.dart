import 'package:flutter/material.dart';
import '../../models/user_model.dart'; // Ensure this points to the correct location

class ConfirmationScreen extends StatelessWidget {
  final User user; // Use 'User' instead of 'UserModel'

  ConfirmationScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Confirmation')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                'A confirmation code has been sent to ${user.phoneNumber.toString()}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to the home screen after confirmation
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: Text('Proceed to Home Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
