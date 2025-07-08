import 'package:flutter/material.dart';

class ActivityHistoryScreen extends StatelessWidget {
  final List<Map<String, String>> activities = [
    {
      "serviceName": "Cleaning",
      "provider": "John's Cleaners",
      "status": "Completed"
    },
    {
      "serviceName": "Laundry",
      "provider": "Fresh Laundry",
      "status": "Pending"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Activity History")),
      body: ListView.builder(
        itemCount: activities.length,
        itemBuilder: (context, index) {
          var activity = activities[index];
          return ListTile(
            title: Text(activity["serviceName"]!),
            subtitle: Text("Provider: ${activity["provider"]}"),
            trailing: Text(activity["status"]!),
          );
        },
      ),
    );
  }
}
