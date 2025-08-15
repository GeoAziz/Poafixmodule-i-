import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text("Change Password"),
              onTap: () {
                // Handle change password
              },
            ),
            ListTile(
              title: Text("Notifications"),
              onTap: () {
                // Handle notifications settings
              },
            ),
          ],
        ),
      ),
    );
  }
}
