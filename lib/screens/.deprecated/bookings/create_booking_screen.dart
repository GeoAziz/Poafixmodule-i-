import 'package:flutter/material.dart';

class BookingListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Bookings')),
      body: Center(
        child: Text('List of your bookings will be displayed here.'),
      ),
    );
  }
}
