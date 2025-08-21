import 'package:flutter/material.dart';
import '../../models/service_category_model.dart';
import '../../models/user_model.dart';
import '../../services/provider_service.dart'; // <-- Add this import

class EnhancedBookingScreen extends StatefulWidget {
  final User user;
  final ServiceCategoryModel selectedService;
  final dynamic userLocation;

  const EnhancedBookingScreen({
    super.key,
    required this.user,
    required this.selectedService,
    required this.userLocation,
  });

  @override
  _EnhancedBookingScreenState createState() => _EnhancedBookingScreenState();
}

class _EnhancedBookingScreenState extends State<EnhancedBookingScreen> {
  bool _isLoading = true;
  List<dynamic> _providers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNearbyProviders();
  }

  Future<void> _fetchNearbyProviders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final providers = await ProviderService.fetchNearbyProviders(
        latitude: widget.userLocation?.latitude ?? 0.0,
        longitude: widget.userLocation?.longitude ?? 0.0,
        radius: 5000,
        serviceType: widget.selectedService.id,
      );
      setState(() {
        _providers = providers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch providers. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Finding nearby providers...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Providers')),
        body: Center(child: Text(_error!)),
      );
    }

    if (_providers.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Providers')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No providers found nearby.',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _fetchNearbyProviders,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Select a Provider')),
      body: ListView.builder(
        itemCount: _providers.length,
        itemBuilder: (context, index) {
          final provider = _providers[index];
          return ListTile(
            leading: Icon(Icons.person, color: Colors.blue),
            title: Text(provider['name'] ?? 'Provider'),
            subtitle: Text(provider['businessName'] ?? ''),
            trailing: ElevatedButton(
              child: Text('Book'),
              onPressed: () {
                // Proceed to booking details or confirmation
              },
            ),
          );
        },
      ),
    );
  }
}
