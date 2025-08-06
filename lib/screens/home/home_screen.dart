import 'package:flutter/material.dart';
// import 'package:poafix/screens/select_service.dart'; // Update this path if your SelectService widget is in a different location
import 'package:poafix/screens/bookings/bookings_screen.dart';
import 'package:poafix/screens/services/service_selection_screen.dart'; // Correct import for ServiceSelectionScreen
import 'package:poafix/screens/quick_actions/schedule_screen.dart';
import 'package:poafix/screens/quick_actions/history_screen.dart';
import 'package:poafix/screens/quick_actions/saved_screen.dart';
import 'package:poafix/screens/notifications/notification_screen.dart'
    as notification;
import 'package:poafix/screens/payment_methods_screen.dart';
import 'package:poafix/screens/billing_history_screen.dart';
import 'package:poafix/screens/refer_a_friend_screen.dart';
import 'package:poafix/screens/follow_us_screen.dart';
import 'package:poafix/screens/auth/login_screen.dart'; // Corrected import path
import 'package:poafix/models/user_model.dart';
import 'package:poafix/screens/profile/profile_screen.dart'; // Import ProfileScreen

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int unreadNotifications = 5; // Simulating unread notifications

  List<Widget> get _screens => [
        _buildHomeTab(), // Home tab with dashboard
        ServiceSelectionScreen(user: widget.user), // Use ServiceSelectionScreen for Search tab
        BookingsScreen(user: widget.user), // Bookings tab
        ProfileScreen(user: widget.user), // Profile tab
      ];

  Widget _buildHomeTab() {
    return HomeScreenContent(user: widget.user);
  }

  // Redirect to login screen if the user is not authenticated
  void _redirectToLogin() {
    Future.delayed(Duration.zero, () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => LoginScreen()), // Navigate to login screen
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('poafix'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        notification.NotificationsScreen(user: widget.user)),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.user.name),
              accountEmail: Text(widget.user.email ??
                  'No email provided'), // Fixed nullable email
              currentAccountPicture: _buildUserAvatar(),
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              trailing: unreadNotifications > 0
                  ? CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$unreadNotifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          notification.NotificationsScreen(user: widget.user)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.payment),
              title: Text('Payment Methods'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PaymentMethodsScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Billing History'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BillingHistoryScreen()),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Log Out'),
              onTap: () {
                _logoutWithAnimation(context);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.share),
              title: Text('Refer a Friend'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReferAFriendScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.link),
              title: Text('Follow Us'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FollowUsScreen()),
                );
              },
            ),
            Divider(),
            ListTile(
              title: Text('App Version: 1.0.0'),
              onTap: () {
                // Display app version info
              },
            ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home', arguments: widget.user);
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceSelectionScreen(user: widget.user),
                ),
              );
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/bookings', arguments: widget.user);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile', arguments: widget.user);
              break;
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
    );
  }

  // Log out with animation
  void _logoutWithAnimation(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: LoginScreen(), // Navigate to LoginScreen
          );
        },
        transitionDuration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return CircleAvatar(
      backgroundColor: Colors.blue,
      child: Text(
        widget.user.name[0].toUpperCase(),
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}

class HomeScreenContent extends StatelessWidget {
  final User user; // Added user parameter

  HomeScreenContent({required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          _buildSearchBar(),
          _buildPopularCategories(),
          _buildQuickActions(context),
          _buildPromotionalBanner(),
          _buildTopRatedProfessionals(),
          _buildTestimonials(),
          _buildExploreNearbyServices(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        "Welcome back, ${user.name}! 😊", // Fetch the user's name dynamically
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search for services...",
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildPopularCategories() {
    final List<Map<String, dynamic>> categories = [
      {"icon": Icons.cleaning_services, "label": "Cleaning"},
      {"icon": Icons.plumbing, "label": "Plumbing"},
      {"icon": Icons.nature, "label": "Gardening"},
      {"icon": Icons.electrical_services, "label": "Electrical"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Popular Categories",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                // Navigate to the respective category
              },
              child: Card(
                elevation: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(categories[index]["icon"], size: 40),
                    SizedBox(height: 8),
                    Text(categories[index]["label"]),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {"icon": Icons.schedule, "label": "Schedule", "route": ScheduleScreen()},
      {"icon": Icons.history, "label": "History", "route": HistoryScreen()},
      {"icon": Icons.bookmark, "label": "Saved", "route": SavedScreen()},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: actions.map((action) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => action["route"]),
                  );
                },
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(action["icon"], size: 30),
                        SizedBox(height: 8),
                        Text(action["label"]),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionalBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "Special Offer: Get 20% off on your first booking!",
        style: TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTopRatedProfessionals() {
    final List<Map<String, dynamic>> professionals = [
      {"name": "Adan Galma", "designation": "Plumber", "rating": 4.5},
      {"name": "Harun Madowe", "designation": "Electrician", "rating": 4.8},
      {"name": "Hassan AbdulAziz", "designation": "Gardener", "rating": 4.7},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Top Rated Professionals",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Column(
            children: professionals.map((professional) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(professional["name"]),
                  subtitle: Text(professional["designation"]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.orange),
                      Text("${professional["rating"]}"),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonials() {
    final List<Map<String, String>> testimonials = [
      {
        "name": "Michael Thompson",
        "review": "Great service, highly recommend!",
      },
      {
        "name": "Sarah Wilson",
        "review": "Fast and reliable, will book again!",
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Customer Testimonials",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Column(
            children: testimonials.map((testimonial) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(testimonial["name"]!),
                  subtitle: Text(testimonial["review"]!),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreNearbyServices() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        "Explore Nearby Services",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
