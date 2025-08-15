import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../services/provider_service.dart';
import '../service_provider_list_screen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class AdvancedSearchScreen extends StatefulWidget {
  final String? initialService;
  final LatLng? initialLocation;

  const AdvancedSearchScreen({
    super.key,
    this.initialService,
    this.initialLocation,
  });

  @override
  _AdvancedSearchScreenState createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final _searchController = TextEditingController();

  // Search filters
  String _selectedService = '';
  double _maxDistance = 5.0; // km
  double _minRating = 0.0;
  RangeValues _priceRange = const RangeValues(0, 1000);
  bool _isAvailableNow = false;
  bool _isVerified = false;
  String _sortBy = 'distance'; // distance, rating, price, availability

  // Location data
  LatLng? _selectedLocation;
  String _locationText = 'Current Location';

  // Service types
  final List<String> _serviceTypes = [
    'Plumbing',
    'Electrical',
    'Cleaning',
    'Painting',
    'Gardening',
    'Carpentry',
    'HVAC',
    'Pest Control',
    'Moving',
    'Handyman'
  ];

  @override
  void initState() {
    super.initState();
    _selectedService = widget.initialService ?? '';
    _selectedLocation = widget.initialLocation;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (_selectedLocation == null) {
      try {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _locationText = 'Current Location';
        });
      } catch (e) {
        // Default to Nairobi if location access fails
        setState(() {
          _selectedLocation = const LatLng(-1.2921, 36.8219);
          _locationText = 'Nairobi, Kenya';
        });
      }
    }
  }

  Future<void> _selectLocation() async {
    // Navigate to location picker
    final result = await Navigator.pushNamed(
      context,
      '/location-picker',
      arguments: _selectedLocation,
    );

    if (result != null && result is Map) {
      setState(() {
        _selectedLocation = LatLng(result['lat'], result['lng']);
        _locationText = result['address'] ?? 'Selected Location';
      });
    }
  }

  void _performSearch() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    if (_selectedService.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service type')),
      );
      return;
    }

    // Navigate to results with filters
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          searchQuery: _searchController.text,
          serviceType: _selectedService,
          location: _selectedLocation!,
          maxDistance: _maxDistance,
          minRating: _minRating,
          priceRange: _priceRange,
          isAvailableNow: _isAvailableNow,
          isVerified: _isVerified,
          sortBy: _sortBy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Services'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What service do you need?',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search for services...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Service type selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Category',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedService.isEmpty ? null : _selectedService,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select a service',
                      ),
                      items: _serviceTypes.map((service) {
                        return DropdownMenuItem(
                          value: service,
                          child: Text(service),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedService = value ?? '';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectLocation,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_locationText)),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Filters
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filters',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Distance filter
                    Text(
                        'Maximum Distance: ${_maxDistance.toStringAsFixed(1)} km'),
                    Slider(
                      value: _maxDistance,
                      min: 1.0,
                      max: 50.0,
                      divisions: 49,
                      onChanged: (value) {
                        setState(() {
                          _maxDistance = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Rating filter
                    const Text('Minimum Rating'),
                    RatingBar.builder(
                      initialRating: _minRating,
                      minRating: 0,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 30,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _minRating = rating;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Price range filter
                    Text(
                        'Price Range: KES ${_priceRange.start.round()} - KES ${_priceRange.end.round()}'),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 5000,
                      divisions: 50,
                      labels: RangeLabels(
                        'KES ${_priceRange.start.round()}',
                        'KES ${_priceRange.end.round()}',
                      ),
                      onChanged: (values) {
                        setState(() {
                          _priceRange = values;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Quick filters
                    CheckboxListTile(
                      title: const Text('Available Now'),
                      value: _isAvailableNow,
                      onChanged: (value) {
                        setState(() {
                          _isAvailableNow = value ?? false;
                        });
                      },
                    ),

                    CheckboxListTile(
                      title: const Text('Verified Providers Only'),
                      value: _isVerified,
                      onChanged: (value) {
                        setState(() {
                          _isVerified = value ?? false;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Sort options
                    const Text('Sort By'),
                    DropdownButtonFormField<String>(
                      value: _sortBy,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'distance', child: Text('Distance')),
                        DropdownMenuItem(
                            value: 'rating', child: Text('Highest Rating')),
                        DropdownMenuItem(
                            value: 'price_low',
                            child: Text('Price: Low to High')),
                        DropdownMenuItem(
                            value: 'price_high',
                            child: Text('Price: High to Low')),
                        DropdownMenuItem(
                            value: 'availability', child: Text('Availability')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value ?? 'distance';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Search button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _performSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Search Services',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;
  final String serviceType;
  final LatLng location;
  final double maxDistance;
  final double minRating;
  final RangeValues priceRange;
  final bool isAvailableNow;
  final bool isVerified;
  final String sortBy;

  const SearchResultsScreen({
    super.key,
    required this.searchQuery,
    required this.serviceType,
    required this.location,
    required this.maxDistance,
    required this.minRating,
    required this.priceRange,
    required this.isAvailableNow,
    required this.isVerified,
    required this.sortBy,
  });

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Map<String, dynamic>> _providers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchProviders();
  }

  Future<void> _searchProviders() async {
    setState(() => _isLoading = true);
    try {
      final providersResponse =
          await ProviderService.searchProvidersWithFilters(
        serviceType: widget.serviceType,
        location: {
          'lat': widget.location.latitude,
          'lng': widget.location.longitude,
        },
        radius: widget.maxDistance,
        minRating: widget.minRating,
        maxPrice: widget.priceRange.end,
        availability: widget.isAvailableNow,
        sortBy: widget.sortBy,
      );
      // Expecting a response with a 'providers' list
      final providers = providersResponse['providers'] ?? [];
      setState(() {
        _providers = List<Map<String, dynamic>>.from(providers);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.serviceType} Services'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _searchProviders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _providers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No providers found'),
                          const SizedBox(height: 8),
                          const Text('Try adjusting your filters'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Modify Search'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Results summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.grey[100],
                          child: Row(
                            children: [
                              Text(
                                '${_providers.length} providers found',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Modify Filters'),
                              ),
                            ],
                          ),
                        ),

                        // Results list
                        Expanded(
                          child: ListView.builder(
                            itemCount: _providers.length,
                            itemBuilder: (context, index) {
                              return ProviderSearchCard(
                                provider: _providers[index],
                                searchLocation: widget.location,
                                onTap: () =>
                                    _navigateToBooking(_providers[index]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  void _navigateToBooking(Map<String, dynamic> provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceProviderListScreen(
          serviceType: widget.serviceType,
          selectedServices: [],
          initialLocation: widget.location,
          clientId: 'current_user_id', // Get from auth
        ),
      ),
    );
  }
}

class ProviderSearchCard extends StatelessWidget {
  final Map<String, dynamic> provider;
  final LatLng searchLocation;
  final VoidCallback onTap;

  const ProviderSearchCard({
    super.key,
    required this.provider,
    required this.searchLocation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rating = provider['rating']?.toDouble() ?? 0.0;
    final distance = _calculateDistance();
    final isAvailable = provider['isAvailable'] ?? false;
    final isVerified = provider['isVerified'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Provider avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      (provider['businessName'] ?? 'P')[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Provider info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider['businessName'] ?? 'Service Provider',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isVerified)
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 20,
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Text(
                          provider['serviceOffered'] ?? 'Service',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Rating and distance
                        Row(
                          children: [
                            RatingBarIndicator(
                              rating: rating,
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${rating.toStringAsFixed(1)} (${provider['totalRatings'] ?? 0})',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            Text(
                              '${distance.toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Price and availability
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isAvailable ? 'Available' : 'Busy',
                      style: TextStyle(
                        color:
                            isAvailable ? Colors.green[700] : Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (provider['basePrice'] != null)
                    Text(
                      'From KES ${provider['basePrice']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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

  double _calculateDistance() {
    try {
      if (provider['location'] == null ||
          provider['location']['coordinates'] == null) {
        return 0.0;
      }

      final coordinates = provider['location']['coordinates'] as List;
      if (coordinates.length < 2) {
        return 0.0;
      }

      final providerLng = (coordinates[0] as num).toDouble();
      final providerLat = (coordinates[1] as num).toDouble();

      return Geolocator.distanceBetween(
            searchLocation.latitude,
            searchLocation.longitude,
            providerLat,
            providerLng,
          ) /
          1000; // Convert to kilometers
    } catch (e) {
      print('Error calculating distance: $e');
      return 0.0;
    }
  }
}
