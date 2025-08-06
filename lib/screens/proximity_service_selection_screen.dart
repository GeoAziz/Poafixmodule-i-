import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../models/service_category.dart';
import '../services/proximity_service.dart';
import '../services/location_service.dart';
import 'enhanced_booking_screen.dart';
import '../search/xcombo_provider_search_screen.dart';

class ProximityServiceSelectionScreen extends StatefulWidget {
  final User user;

  const ProximityServiceSelectionScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  _ProximityServiceSelectionScreenState createState() =>
      _ProximityServiceSelectionScreenState();
}

class _ProximityServiceSelectionScreenState
    extends State<ProximityServiceSelectionScreen>
    with SingleTickerProviderStateMixin {
  List<ServiceCategory> _services = [];
  bool _isLoading = true;
  String? _error;
  Position? _currentLocation;
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadServices();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check location permission
      final locationService = LocationService();
      final hasPermission = await locationService.hasLocationPermission();
      if (!hasPermission) {
        final granted = await locationService.requestLocationPermission();
        if (!granted) {
          setState(() {
            _error = 'Location permission is required to find nearby providers';
            _isLoading = false;
          });
          return;
        }
      }

      // Get current location
      _currentLocation = await locationService.getCurrentLocation();
      
      // Load services with proximity data
      final services = await ProximityService.getServicesWithProximity(
        latitude: _currentLocation?.latitude,
        longitude: _currentLocation?.longitude,
      );

      setState(() {
        _services = services;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = 'Error loading services: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<ServiceCategory> get _filteredServices {
    if (_searchQuery.isEmpty) return _services;
    
    return _services.where((service) =>
      service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      service.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      service.services.any((s) => s.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Finding nearby providers...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: _buildErrorWidget(),
            )
          else ...[
            _buildSearchBar(),
            _buildLocationHeader(),
            _buildServicesList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFFEC4899),
              ],
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
                    'Professional Services',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Find trusted professionals near you',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search for services...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    if (_currentLocation == null) return SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Color(0xFF6366F1),
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Services available in your area',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _loadServices,
              icon: Icon(Icons.refresh, size: 18),
              label: Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    final filteredServices = _filteredServices;

    return SliverPadding(
      padding: EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.1,
                    1.0,
                    curve: Curves.easeOutCubic,
                  ),
                )),
                child: _buildServiceCard(filteredServices[index]),
              ),
            );
          },
          childCount: filteredServices.length,
        ),
      ),
    );
  }

  Widget _buildServiceCard(ServiceCategory service) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectService(service),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: service.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        service.icon,
                        color: service.color,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: TextStyle(
                              fontSize: 18,
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (service.nearbyProviders > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.people,
                      '${service.nearbyProviders} providers nearby',
                      Colors.blue,
                    ),
                    SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.star,
                      '${service.rating}',
                      Colors.amber,
                    ),
                    SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.access_time,
                      service.estimatedTime,
                      Colors.green,
                    ),
                  ],
                ),
                if (service.nearbyProviders > 0) ...[
                  SizedBox(height: 12),
                  Text(
                    'Starting from KSh ${service.basePrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color, // Fix: remove [700]
          ),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color, // Fix: remove [700]
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadServices,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectService(ServiceCategory service) {
    if (service.nearbyProviders == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No providers available for this service in your area'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => XComboProviderSearchScreen(
          serviceId: service.id,
          serviceName: service.name,
          user: widget.user,
        ),
      ),
    );
  }
}
