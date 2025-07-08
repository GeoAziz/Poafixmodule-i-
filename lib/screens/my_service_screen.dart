import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Service Screen',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyServiceScreen(),
    );
  }
}

class MyServiceScreen extends StatefulWidget {
  @override
  _MyServiceScreenState createState() => _MyServiceScreenState();
}

class _MyServiceScreenState extends State<MyServiceScreen>
    with TickerProviderStateMixin {
  // List of services for illustration
  final List<Service> services = [
    Service(
      name: 'House Cleaning',
      description: 'Deep cleaning of your house or apartment',
      price: '\$50',
      rating: 4.5,
      available: true,
    ),
    Service(
      name: 'Plumbing',
      description: 'Fix leaks and maintain plumbing systems',
      price: '\$75',
      rating: 4.7,
      available: true,
    ),
    Service(
      name: 'Gardening',
      description: 'Landscaping and lawn care services',
      price: '\$40',
      rating: 4.2,
      available: false,
    ),
  ];

  // Animation Controller
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Slide animation setup
    _animationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // No back button
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Services'),
            IconButton(
              icon: Icon(Icons.add_circle_outline),
              onPressed: () {
                // Action for adding a new service
              },
            ),
          ],
        ),
        backgroundColor: Colors.green,
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return ServiceCard(
              service: service,
              onEdit: () {
                // Edit service action
              },
              onToggleAvailability: () {
                setState(() {
                  service.available = !service.available;
                });
              },
            );
          },
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onEdit;
  final VoidCallback onToggleAvailability;

  const ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(15),
        title: Text(
          service.name,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.description),
            SizedBox(height: 5),
            Text('Price: ${service.price}'),
            SizedBox(height: 5),
            Text('Rating: ${service.rating} ★'),
            SizedBox(height: 5),
            Text(
              'Availability: ${service.available ? 'Available' : 'Unavailable'}',
              style: TextStyle(
                color: service.available ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.green),
        onTap: onEdit,
        onLongPress: onToggleAvailability,
      ),
    );
  }
}

class Service {
  String name;
  String description;
  String price;
  double rating;
  bool available;

  Service({
    required this.name,
    required this.description,
    required this.price,
    required this.rating,
    required this.available,
  });
}
