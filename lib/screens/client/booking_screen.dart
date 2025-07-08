import 'package:flutter/material.dart';

class ClientBookingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Bookings')),
      body: ListView(
        children: [
          ListTile(title: Text('Booking 1 - Pending')),
          ListTile(title: Text('Booking 2 - Accepted')),
          ListTile(title: Text('Booking 3 - Completed')),
        ],
      ),
    );
  }
}
