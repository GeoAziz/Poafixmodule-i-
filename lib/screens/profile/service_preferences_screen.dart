import 'package:flutter/material.dart';

class ServicePreferencesScreen extends StatefulWidget {
  @override
  _ServicePreferencesScreenState createState() =>
      _ServicePreferencesScreenState();
}

class _ServicePreferencesScreenState extends State<ServicePreferencesScreen> {
  List<String> services = ["Cleaning", "Cooking", "Laundry", "Gardening"];
  Map<String, bool> selectedServices = {};

  @override
  void initState() {
    super.initState();
    // Initialize selected services as false
    for (var service in services) {
      selectedServices[service] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Service Preferences")),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: services.map((service) {
          return CheckboxListTile(
            title: Text(service),
            value: selectedServices[service],
            onChanged: (bool? value) {
              setState(() {
                selectedServices[service] = value!;
              });
            },
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Submit the updated preferences to backend
        },
        child: Icon(Icons.save),
      ),
    );
  }
}
