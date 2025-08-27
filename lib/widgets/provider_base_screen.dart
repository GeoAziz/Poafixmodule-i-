import 'package:flutter/material.dart';
import '../screens/bookings/bookings_screen.dart';
import '../models/user_model.dart';
import '../widgets/provider_drawer.dart';

class ProviderBaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showDrawer;
  final bool showAppBar;
  final int currentIndex;
  final String providerId;
  final User user;

  const ProviderBaseScreen({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showDrawer = true,
    this.showAppBar = true,
    this.currentIndex = 0,
    this.providerId = '',
    required this.user,
  });

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
              providerId: providerId,
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onNavigationTap(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BookingsScreen(user: user, showNavigation: true),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }
}
