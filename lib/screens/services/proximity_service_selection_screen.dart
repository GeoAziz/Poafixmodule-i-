import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/user_model.dart';
import '../../models/service_category_model.dart';
import '../../services/enhanced_proximity_service.dart';
import '../booking/enhanced_booking_screen.dart';

class ProximityServiceSelectionScreen extends StatefulWidget {
  final User user;

  const ProximityServiceSelectionScreen({super.key, required this.user});

  @override
  _ProximityServiceSelectionScreenState createState() =>
      _ProximityServiceSelectionScreenState();
}

class _ProximityServiceSelectionScreenState
    extends State<ProximityServiceSelectionScreen> {
  List<ServiceCategoryModel> _serviceCategories = [];
  bool _isLoading = true;
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadServiceCategories();
  }

  Future<void> _loadServiceCategories() async {
    setState(() => _isLoading = true);
    try {
      _currentLocation = await Geolocator.getCurrentPosition();
      _serviceCategories = await ProximityService().getServicesWithProximity(
        latitude: _currentLocation?.latitude,
        longitude: _currentLocation?.longitude,
        radiusKm: 5.0,
      );
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading services: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Choose Home Service')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _serviceCategories.length,
              itemBuilder: (context, index) {
                final service = _serviceCategories[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(service.icon, color: service.color),
                    title: Text(service.name),
                    subtitle: Text(
                      '${service.nearbyProviders} providers nearby',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EnhancedBookingScreen(
                            user: widget.user,
                            selectedService: service,
                            userLocation: _currentLocation,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
