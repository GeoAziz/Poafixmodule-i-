import 'package:flutter/material.dart';

class ServiceProviderHomeDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Service Dashboard')),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(title: Text('Dashboard')),
            ListTile(title: Text('My Services')),
            ListTile(title: Text('Bookings')),
            ListTile(title: Text('Earnings')),
            ListTile(title: Text('Profile')),
          ],
        ),
      ),
      body: Column(
        children: [
          Text('Current Bookings Summary'),
          // Add bookings and earnings summary here
        ],
      ),
    );
  }
}
