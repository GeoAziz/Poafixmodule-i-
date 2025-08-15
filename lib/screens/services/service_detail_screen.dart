import 'package:flutter/material.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Service Details')),
      body: Center(
        child: Text('Details of the selected service will be displayed here.'),
      ),
    );
  }
}
