import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FollowUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Follow Us'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Follow Us on Social Media',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Stay connected with us and get updates on new services, offers, and promotions.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.facebook),
                  iconSize: 40,
                  onPressed: () {
                    // Implement navigation to Facebook page or app
                  },
                ),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.twitter),
                  iconSize: 40,
                  onPressed: () {
                    // Implement navigation to Twitter page or app
                  },
                ),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.instagram),
                  iconSize: 40,
                  onPressed: () {
                    // Implement navigation to Instagram page or app
                  },
                ),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.linkedin),
                  iconSize: 40,
                  onPressed: () {
                    // Implement navigation to LinkedIn page or app
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
