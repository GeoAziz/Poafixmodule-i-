import 'package:flutter/material.dart';
import '../client/client_notifications_screen.dart';
// import 'package:poafix/screens/select_service.dart'; // Update this path if your SelectService widget is in a different location
import '../bookings/bookings_screen.dart';
import '../services/service_selection_screen.dart';
import '../quick_actions/schedule_screen.dart';
import '../quick_actions/history_screen.dart';
import '../quick_actions/saved_screen.dart';
import '../notifications/notification_screen.dart' as notification;
import '../payment_methods_screen.dart';
import '../billing_history_screen.dart';
import '../refer_a_friend_screen.dart';
import '../follow_us_screen.dart';
import '../auth/login_screen.dart';
import '../../models/user_model.dart';
import '../profile/profile_screen.dart';
import '../../widgets/bottomnavbar.dart';
import '../../widgets/client_sidepanel.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_count_provider.dart';
// import '../../widgets/client_side_panel.dart'; // Add this import if ClientSidePanel is defined here

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Widget _buildUserAvatar() {
    return CircleAvatar(child: Icon(Icons.person));
  }

  void _logoutWithAnimation(BuildContext context) async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  List<Widget> get _screens => [
    SingleChildScrollView(
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
    ),
    ServiceSelectionScreen(user: widget.user),
    BookingsScreen(user: widget.user),
    ProfileScreen(user: widget.user),
    ClientNotificationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = Provider.of<NotificationCountProvider>(
      context,
    ).unreadCount;
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
                  builder: (context) => notification.NotificationsScreen(user: widget.user),
                ),
              );
            },
          ),
        ],
      ),
      drawer: ClientSidePanel(user: widget.user, parentContext: context),
      body: _screens[_currentIndex],
      bottomNavigationBar: FunctionalBottomNavBar(
        currentIndex: _currentIndex,
        unreadCount: unreadCount,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(
                context,
                '/home',
                arguments: widget.user,
              );
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
              Navigator.pushReplacementNamed(
                context,
                '/bookings',
                arguments: widget.user,
              );
              break;
            case 3:
              Navigator.pushReplacementNamed(
                context,
                '/profile',
                arguments: widget.user,
              );
              break;
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ClientNotificationsScreen(),
                ),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        "Welcome back, ${widget.user.name}! 😊", // Fetch the user's name dynamically
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
      {"name": "Sarah Wilson", "review": "Fast and reliable, will book again!"},
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
