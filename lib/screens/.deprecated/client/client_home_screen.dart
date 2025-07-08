import 'package:flutter/material.dart';

void main() {
  runApp(ClientApp());
}

class ClientApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ClientHomeScreen(),
    );
  }
}

class ClientHomeScreen extends StatefulWidget {
  @override
  _ClientHomeScreenState createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentIndex = 0;

  // List of pages for bottom navigation
  final List<Widget> _pages = [
    ClientHome(),
    ServiceListScreen(),
    BookingScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Add logout functionality here
            },
          ),
        ],
      ),
      body: _pages[_currentIndex], // Display selected screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Home Page (Initial screen)
class ClientHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, Client!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text(
            'Here are some options for you:',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 10),
          ListTile(
            title: Text('View Services'),
            leading: Icon(Icons.search),
            onTap: () {
              // Navigate to the service list
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ServiceListScreen()),
              );
            },
          ),
          ListTile(
            title: Text('View Bookings'),
            leading: Icon(Icons.book),
            onTap: () {
              // Navigate to the booking screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookingScreen()),
              );
            },
          ),
          ListTile(
            title: Text('Account Settings'),
            leading: Icon(Icons.account_circle),
            onTap: () {
              // Navigate to account settings
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
          ListTile(
            title: Text('Support'),
            leading: Icon(Icons.support),
            onTap: () {
              // Navigate to support screen
            },
          ),
        ],
      ),
    );
  }
}

// Service List Screen (dummy data)
class ServiceListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        ListTile(
          title: Text('Home Cleaning'),
          leading: Icon(Icons.cleaning_services),
          onTap: () {
            // Navigate to specific service provider details
          },
        ),
        ListTile(
          title: Text('Plumbing Services'),
          leading: Icon(Icons.plumbing),
          onTap: () {
            // Navigate to plumbing service providers
          },
        ),
        ListTile(
          title: Text('Electrician Services'),
          leading: Icon(Icons.electric_car),
          onTap: () {
            // Navigate to electrician service providers
          },
        ),
        ListTile(
          title: Text('Beauty Services'),
          leading: Icon(Icons.face),
          onTap: () {
            // Navigate to beauty service providers
          },
        ),
      ],
    );
  }
}

// Booking Screen (dummy data)
class BookingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        ListTile(
          title: Text('Home Cleaning - Appointment on Jan 20'),
          leading: Icon(Icons.calendar_today),
          onTap: () {
            // Navigate to booking details or update screen
          },
        ),
        ListTile(
          title: Text('Plumbing - Appointment on Jan 22'),
          leading: Icon(Icons.calendar_today),
          onTap: () {
            // Navigate to booking details or update screen
          },
        ),
      ],
    );
  }
}

// Profile Screen
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'),
          ),
          SizedBox(height: 16),
          Text(
            'Client Name',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('client.email@example.com'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to edit profile
            },
            child: Text('Edit Profile'),
          ),
          ElevatedButton(
            onPressed: () {
              // Navigate to change password screen
            },
            child: Text('Change Password'),
          ),
        ],
      ),
    );
  }
}
