import 'package:flutter/material.dart';

class ServiceListScreen extends StatelessWidget {
  const ServiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Services'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text(
          'List of services will be displayed here.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
