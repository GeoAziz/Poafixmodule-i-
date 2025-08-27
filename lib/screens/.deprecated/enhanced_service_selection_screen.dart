import 'package:flutter/material.dart';
import '../../core/models/user_model.dart' show UserModel;
import '../../models/service_category_model.dart';
import '../../models/service_category.dart';
import '../booking/booking_details_screen.dart';

class EnhancedServiceSelectionScreen extends StatefulWidget {
  final UserModel user;

  const EnhancedServiceSelectionScreen({
    super.key,
    required this.user,
  });

  @override
  EnhancedServiceSelectionScreenState createState() =>
      EnhancedServiceSelectionScreenState();
}

class EnhancedServiceSelectionScreenState
    extends State<EnhancedServiceSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentIndex = 1;

  final List<ServiceCategoryModel> _services = [
    ServiceCategoryModel(
      id: 'plumbing',
      name: 'Plumbing',
      icon: Icons.plumbing,
      color: Colors.blue,
      description: 'Water pipes, repairs, installations',
      basePrice: 1500.0,
      nearbyProviders: 15,
      rating: 4.5,
      estimatedTime: '2-4 hours',
      subServices: [
        'Pipe Installation',
        'Leak Repairs',
        'Drain Cleaning',
        'Water Heater Service',
        'Toilet Installation',
      ],
    ),
    ServiceCategoryModel(
      id: 'electrical',
      name: 'Electrical',
      icon: Icons.electrical_services,
      color: Colors.orange,
      description: 'Wiring, repairs, installations',
      basePrice: 2000.0,
      nearbyProviders: 12,
      rating: 4.7,
      estimatedTime: '1-3 hours',
      subServices: [
        'Wiring Installation',
        'Socket Repairs',
        'Light Fixtures',
        'Circuit Breaker',
        'Electrical Inspection',
      ],
    ),
    ServiceCategoryModel(
      id: 'cleaning',
      name: 'House Cleaning',
      icon: Icons.cleaning_services,
      color: Colors.green,
      description: 'Professional home & office cleaning',
      basePrice: 800.0,
      nearbyProviders: 25,
      rating: 4.6,
      estimatedTime: '2-6 hours',
      subServices: [
        'Deep Cleaning',
        'Regular Cleaning',
        'Move-in/out Cleaning',
        'Office Cleaning',
        'Window Cleaning',
      ],
    ),
    ServiceCategoryModel(
      id: 'painting',
      name: 'Painting',
      icon: Icons.format_paint,
      color: Colors.purple,
      description: 'Interior & exterior painting services',
      basePrice: 1200.0,
      nearbyProviders: 8,
      rating: 4.4,
      estimatedTime: '4-8 hours',
      subServices: [
        'Interior Painting',
        'Exterior Painting',
        'Wall Preparation',
        'Color Consultation',
        'Touch-up Services',
      ],
    ),
  ];

  List<ServiceCategoryModel> get _filteredServices {
    if (_searchQuery.isEmpty) return _services;
    return _services
        .where((service) =>
            service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            service.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            service.subServices.any(
                (s) => s.toLowerCase().contains(_searchQuery.toLowerCase())))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blue[600],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue[600]!, Colors.blue[800]!],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Hi ${widget.user.name}! 👋',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'What service do you need today?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 20),
                        // Search Bar
                        TextField(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search services, providers...',
                            prefixIcon:
                                Icon(Icons.search, color: Colors.grey[600]),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Quick Stats
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(26),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      'Available\nProviders', '60+', Icons.people, Colors.blue),
                  _buildStatItem('Avg Response\nTime', '< 30min',
                      Icons.access_time, Colors.orange),
                  _buildStatItem(
                      'Completion\nRate', '98%', Icons.verified, Colors.green),
                ],
              ),
            ),
          ),

          // Services Grid
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: _filteredServices.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyState())
                : SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = _filteredServices[index];
                        return _buildEnhancedServiceCard(service);
                      },
                      childCount: _filteredServices.length,
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedServiceCard(ServiceCategoryModel service) {
    return GestureDetector(
      onTap: () => _navigateToBookingDetails(service),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(26),
              spreadRadius: 1,
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: service.color.withAlpha(26),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(service.icon, color: service.color, size: 32),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          service.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Service Stats
              Row(
                children: [
                  _buildServiceStat(Icons.people,
                      '${service.nearbyProviders} providers', Colors.blue),
                  SizedBox(width: 16),
                  _buildServiceStat(
                      Icons.star, '${service.rating}', Colors.orange),
                  SizedBox(width: 16),
                  _buildServiceStat(
                      Icons.access_time, service.estimatedTime, Colors.green),
                ],
              ),

              SizedBox(height: 16),

              // Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Starting from',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'KES ${service.basePrice}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: service.color,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Book Now Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToBookingDetails(service),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: service.color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Book Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No services found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() => _currentIndex = index);
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home',
                arguments: widget.user);
            break;
          case 1:
            // Already on search screen
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/bookings',
                arguments: widget.user);
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/profile',
                arguments: widget.user);
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_circle), label: 'Profile'),
      ],
    );
  }

  void _navigateToBookingDetails(ServiceCategoryModel service) {
    // Convert ServiceCategoryModel to ServiceCategory
    final selectedService = ServiceCategory(
      id: service.id,
      name: service.name,
      icon: service.icon,
      color: service.color,
      description: service.description,
      basePrice: service.basePrice,
      providers: service.nearbyProviders,
      rating: service.rating,
      estimatedTime: service.estimatedTime,
      services: service.subServices,
      nearbyProviders: service.nearbyProviders,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(
          user: widget.user,
          selectedService: selectedService,
        ),
      ),
    );
  }
}
