import 'package:flutter/material.dart';
import '../client/client_notifications_screen.dart';
import 'components/category_card.dart';
import 'components/professional_card.dart';
import 'components/testimonial_card.dart';
// import 'package:poafix/screens/select_service.dart'; // Update this path if your SelectService widget is in a different location
import '../bookings/bookings_screen.dart';
import '../services/service_selection_screen.dart';
import '../quick_actions/schedule_screen.dart';
import '../quick_actions/history_screen.dart';
import '../quick_actions/saved_screen.dart';
// ...existing code...
import '../../models/user_model.dart';
import '../profile/profile_screen.dart';
import '../../widgets/bottomnavbar.dart';
import '../../widgets/client_sidepanel.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/notification_count_provider.dart';
// import '../../widgets/client_side_panel.dart'; // Add this import if ClientSidePanel is defined here

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // ...existing code...

  List<Widget> get _screens => [
    SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection()
              .animate()
              .fade(duration: 600.ms)
              .slideY(begin: 0.2, end: 0, duration: 600.ms),
          _buildSearchBar()
              .animate()
              .fade(duration: 600.ms, delay: 100.ms)
              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 100.ms),
          _buildPopularCategories()
              .animate()
              .fade(duration: 600.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 200.ms),
          _buildQuickActions(context)
              .animate()
              .fade(duration: 600.ms, delay: 300.ms)
              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 300.ms),
          _buildPromotionalBanner()
              .animate()
              .shimmer(duration: 1200.ms)
              .fade(duration: 600.ms, delay: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 400.ms),
          _buildTopRatedProfessionals()
              .animate()
              .fade(duration: 600.ms, delay: 500.ms)
              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 500.ms),
          _buildTestimonials()
              .animate()
              .fade(duration: 600.ms, delay: 600.ms)
              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 600.ms),
          _buildExploreNearbyServices()
              .animate()
              .fade(duration: 600.ms, delay: 700.ms)
              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 700.ms),
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
    final unreadCount = Provider.of<NotificationCountProvider>(context).count;
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
              setState(() => _currentIndex = 4); // Switch to notifications tab
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
          setState(() => _currentIndex = index); // Tab navigation only
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
            return CategoryCard(
              icon: categories[index]["icon"],
              label: categories[index]["label"],
              onTap: () {
                // TODO: Implement navigation to category details
              },
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
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.lightBlueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Special Offer: Get 20% off on your first booking!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
              return ProfessionalCard(
                name: professional["name"],
                designation: professional["designation"],
                rating: professional["rating"],
                onTap: () {
                  // TODO: Implement navigation to professional profile
                },
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
              return TestimonialCard(
                name: testimonial["name"]!,
                review: testimonial["review"]!,
                onTap: () {
                  // TODO: Implement testimonial details or animation
                },
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
