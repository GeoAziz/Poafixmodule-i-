// refer_a_friend_screen.dart
import 'package:flutter/material.dart';

class ReferAFriendScreen extends StatelessWidget {
  const ReferAFriendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Refer a Friend'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Refer a Friend and Earn Rewards!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Invite your friends to use our service, and you\'ll earn rewards when they make their first booking! Simply share your referral code with them, and they can start enjoying great services.\n\n'
              'How it works:\n\n'
              '1. Share your referral code with friends.\n'
              '2. They sign up and make their first booking.\n'
              '3. Earn rewards once they complete the service.\n\n'
              'Start referring today and earn exciting rewards!',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 32),
            Row(
              children: [
                Icon(Icons.share, size: 40),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // Implement the share functionality here
                  },
                  child: Text('Share Referral Code'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
