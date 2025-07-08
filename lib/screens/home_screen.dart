import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import for Font Awesome icons

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String serviceProviderName = "John Doe"; // Example service provider name

    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to HomeScreen with the logged-in user's name
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(userName: serviceProviderName),
              ),
            );
          },
          child: Text("Login as John Doe"),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String userName; // Accept user name dynamically

  HomeScreen({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              AnimatedContainer(
                duration: Duration(seconds: 1),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade300, blurRadius: 8)
                  ],
                ),
                child: Column(
                  children: [
                    Icon(FontAwesomeIcons.userCircle,
                        size: 100, color: Colors.blue),
                    SizedBox(height: 15),
                    // Display dynamic user name
                    Text(
                      userName,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Welcome to your Dashboard, where you can manage your services and view your stats.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16, color: Colors.black.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              // Other sections like Upcoming Appointments, etc.
              SectionCard(
                title: 'Upcoming Appointments',
                icon: Icons.calendar_today,
                content:
                    'No upcoming appointments. Get ready to accept new requests.',
                onPressed: () {},
              ),
              // Add other SectionCard widgets as needed
            ],
          ),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;
  final VoidCallback onPressed;

  const SectionCard({
    required this.title,
    required this.icon,
    required this.content,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(content,
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.6))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
