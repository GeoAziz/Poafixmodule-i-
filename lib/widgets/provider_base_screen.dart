import 'package:flutter/material.dart';
import '../widgets/provider_drawer.dart';

class ProviderBaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showDrawer; // Add this
  final bool showAppBar; // Add this
  final int currentIndex; // Add this parameter
  final String providerId; // Add providerId parameter

  const ProviderBaseScreen({
    Key? key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showDrawer = true, // Default to true
    this.showAppBar = true, // Default to true
    this.currentIndex = 0, // Add default value
    this.providerId = '', // Add default value
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              leading: showDrawer
                  ? IconButton(
                      icon: Icon(Icons.menu),
                      onPressed: () => scaffoldKey.currentState?.openDrawer(),
                    )
                  : null,
              actions: actions,
            )
          : null,
      drawer: showDrawer
          ? ProviderDrawer(
              userName: 'Sarah Wanjiku',
              businessName: 'Quick Movers Nairobi',
              providerId: providerId ?? '', // Add this line
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onNavigationTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _onNavigationTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/bookings');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }
}
