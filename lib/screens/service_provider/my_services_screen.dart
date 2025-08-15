import 'package:flutter/material.dart';

class ServiceProviderMyServicesScreen extends StatelessWidget {
  const ServiceProviderMyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Services')),
      body: ListView(
        children: [
          ListTile(title: Text('Service 1')),
          ListTile(title: Text('Service 2')),
          ListTile(title: Text('Service 3')),
        ],
      ),
    );
  }
}
