import 'package:flutter/material.dart';

class ClientHomeDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(title: Text('Home')),
            ListTile(title: Text('My Bookings')),
            ListTile(title: Text('Profile')),
          ],
        ),
      ),
      body: Column(
        children: [
          Text('Search Services'),
          // Add Search Bar Widget here
        ],
      ),
    );
  }
}
