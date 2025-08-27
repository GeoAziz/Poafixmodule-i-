import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/models/user_model.dart'; // Use the correct UserModel
import '../../models/user_model.dart' show User;
import '../../models/service_category.dart';
import '../../services/proximity_service.dart';
import '../booking/booking_details_screen.dart'; // Make sure this import path is correct
//import '../enhanced_booking_screen.dart'; // Ensure this import is correct and the file exists

class ServiceSelectionScreen extends StatefulWidget {
  final User user;

  const ServiceSelectionScreen({super.key, required this.user});

  @override
  _ServiceSelectionScreenState createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentIndex = 1;
  List<ServiceCategory> _services = [];
  bool _isLoading = true;
  Position? _currentLocation;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Map<String, dynamic> _proximityStats = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
      backgroundColor: Colors.grey[100],
    );
  }

  @override
  void initState() {
    super.initState();
    print('[ServiceSelectionScreen] initState called');
    print(
      '[ServiceSelectionScreen] Device info: (add device info here if available)',
    );
    // TODO: Import ApiConfig if needed, or remove these lines if not required.
    // print('[ServiceSelectionScreen] ApiConfig.baseUrl: ${ApiConfig.baseUrl}');
    // print('[ServiceSelectionScreen] Endpoint: ${ApiConfig.getEndpointUrl('services/proximity')}');
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadServicesWithProximity();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServicesWithProximity() async {
    try {
      print('[ServiceSelectionScreen] _loadServicesWithProximity called');
      if (mounted) setState(() => _isLoading = true);

      // Get current location
      print('[ServiceSelectionScreen] Fetching current location...');
      _currentLocation = await _getCurrentLocation();
      print(
        '[ServiceSelectionScreen] Current location: ${_currentLocation?.latitude}, ${_currentLocation?.longitude}',
      );

      // Get services with proximity data
      print(
        '[ServiceSelectionScreen] Calling ProximityService.getServicesWithProximity with lat=${_currentLocation?.latitude}, lng=${_currentLocation?.longitude}, radius=15.0',
      );
      final services = await ProximityService.getServicesWithProximity(
        latitude: _currentLocation?.latitude,
        longitude: _currentLocation?.longitude,
        radius: 15.0, // 15km radius
      );
      print('[ServiceSelectionScreen] Services returned: $services');

      // Calculate proximity stats
      int totalNearby = services.fold(
        0,
        (sum, service) => sum + service.nearbyProviders,
      );
      double avgResponse = services.isEmpty
          ? 30.0
          : services.fold(
                  0.0,
                  (sum, service) => sum + service.averageResponse,
                ) /
                services.length;

      _proximityStats = {
        'totalProviders': totalNearby,
        'averageResponse': avgResponse.round(),
        'servicesAvailable': services.length,
        'available24x7': services.where((s) => s.isAvailable24x7).length,
      };
      print('[ServiceSelectionScreen] Proximity stats: $_proximityStats');

      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[ServiceSelectionScreen] Error loading services: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      print('[ServiceSelectionScreen] Checking location permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      print('[ServiceSelectionScreen] Location permission: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print(
          '[ServiceSelectionScreen] Requested location permission, new status: $permission',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        print('[ServiceSelectionScreen] Location permission denied forever');
        return null;
      }

      final position = await Geolocator.getCurrentPosition();
      print('[ServiceSelectionScreen] Current position: $position');
      return position;
    } catch (e) {
      print('[ServiceSelectionScreen] Error getting location: $e');
      return null;
    }
  }

  // Helper: filtered services getter
  List<ServiceCategory> get _filteredServices {
    print(
      '[ServiceSelectionScreen] Filtering services with query: $_searchQuery',
    );
    if (_searchQuery.isEmpty) return _services;
    return _services
        .where(
          (service) =>
              service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              service.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              service.services.any(
                (s) => s.toLowerCase().contains(_searchQuery.toLowerCase()),
              ),
        )
        .toList();
  }

  // Helper: Proximity stat item
  Widget _buildProximityStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fixedOpacity(color, 0.1),
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
          SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Empty state
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

  // Helper: Service stat
  Widget _buildServiceStat(IconData icon, String text, Color color) {
    return Flexible(
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Enhanced service card
  Widget _buildEnhancedServiceCard(ServiceCategory service, int index) {
    return GestureDetector(
      onTap: () {
        print('[ServiceSelectionScreen] Service card tapped: ${service.name}');
        _navigateToBookingDetails(service);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
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
              // Header Row with Proximity Badge
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: fixedOpacity(service.color, 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(service.icon, color: service.color, size: 32),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                service.name,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (service.nearbyProviders > 0)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: service.color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${service.nearbyProviders} nearby',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          service.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (service.isAvailable24x7)
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: fixedOpacity(Colors.green, 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '24/7 Available',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Enhanced Service Stats
              Row(
                children: [
                  _buildServiceStat(
                    Icons.people,
                    '${service.providers} providers',
                    Colors.blue,
                  ),
                  SizedBox(width: 8),
                  _buildServiceStat(
                    Icons.star,
                    '${service.rating}',
                    Colors.orange,
                  ),
                  SizedBox(width: 8),
                  _buildServiceStat(
                    Icons.access_time,
                    '~${service.averageResponse.round()}min',
                    Colors.green,
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Popular Service Badge
              if (service.popularService.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Popular: ${service.popularService}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Price and Book Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Starting from',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                  Container(
                    child: ElevatedButton(
                      onPressed: () => _navigateToBookingDetails(service),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: service.color,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Navigate to booking details
  void _navigateToBookingDetails(ServiceCategory service) {
    print(
      '[ServiceSelectionScreen] Navigating to booking details for service: ${service.name}, user: ${widget.user.id}, location: $_currentLocation',
    );
    final userInstance = User(
      id: widget.user.id,
      name: widget.user.name,
      email: widget.user.email,
      userType: widget.user.userType,
      phone: widget.user.phone,
      token: widget.user.token,
      avatarUrl: widget.user.avatarUrl,
      phoneNumber: widget.user.phoneNumber,
      profilePicUrl: widget.user.profilePicUrl,
      createdAt: widget.user.createdAt,
      preferredCommunication: widget.user.preferredCommunication,
      backupContact: widget.user.backupContact,
      timezone: widget.user.timezone,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsScreen(
          user: _toUserModel(userInstance),
          selectedService: service,
          userLocation: _currentLocation, // Pass location if available
        ),
      ),
    );
  }

  // Helper: Convert User to UserModel
  UserModel _toUserModel(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      userType: user.userType,
    );
  }

  // Helper: Loading screen
  Widget _buildLoadingScreen() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 160,
          floating: false,
          pinned: true,
          backgroundColor: Colors.blue[600],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: EdgeInsets.only(top: 32, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for services...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      print(
                        '[ServiceSelectionScreen] Search query changed: $value',
                      );
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper: Main content
  Widget _buildMainContent() {
    return CustomScrollView(
      slivers: [
        // Enhanced App Bar with Location Info
        SliverAppBar(
          expandedHeight: 280,
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
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Hi ${widget.user.name}! 👋',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Spacer(),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Near You',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                            // Enhanced Search Bar
                            TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                print(
                                  '[ServiceSelectionScreen] Enhanced search bar query changed: $value',
                                );
                                setState(() => _searchQuery = value);
                              },
                              decoration: InputDecoration(
                                hintText: 'Search services, providers...',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey[600],
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          print(
                                            '[ServiceSelectionScreen] Enhanced search bar cleared',
                                          );
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Proximity Stats
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.near_me, color: Colors.blue[600], size: 20),
                    SizedBox(width: 8),
                    Text(
                      'In Your Area (15km radius)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildProximityStatItem(
                      '${_proximityStats['totalProviders'] ?? 0}+',
                      'Available\nProviders',
                      Icons.people,
                      Colors.blue,
                    ),
                    _buildProximityStatItem(
                      '< ${_proximityStats['averageResponse'] ?? 30}min',
                      'Avg Response\nTime',
                      Icons.access_time,
                      Colors.orange,
                    ),
                    _buildProximityStatItem(
                      '${_proximityStats['available24x7'] ?? 0}',
                      '24/7 Available\nServices',
                      Icons.schedule,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Services Grid
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: _filteredServices.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final service = _filteredServices[index];
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      curve: Curves.easeOutBack,
                      margin: EdgeInsets.only(bottom: 16),
                      child: _buildEnhancedServiceCard(service, index),
                    );
                  }, childCount: _filteredServices.length),
                ),
        ),
      ],
    );
  }

  // Helper: Bottom navigation
  // Removed duplicate bottom navigation bar
}

// Helper for opacity replacement
Color fixedOpacity(Color color, double opacity) {
  final o = (opacity.clamp(0.0, 1.0) * 255).round();
  return color.withAlpha(o);
}
