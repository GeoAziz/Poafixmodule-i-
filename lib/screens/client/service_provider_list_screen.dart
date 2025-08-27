import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/user_status_service.dart';

class ServiceProviderListScreen extends StatefulWidget {
  final String serviceType;

  const ServiceProviderListScreen({super.key, required this.serviceType});

  @override
  _ServiceProviderListScreenState createState() =>
      _ServiceProviderListScreenState();
}

class _ServiceProviderListScreenState extends State<ServiceProviderListScreen> {
  List<dynamic> _providers = [];
  bool _isLoading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    // Use hardcoded Nairobi coordinates for testing, matching the seeded DB
    double latitude;
    double longitude;
    switch (widget.serviceType.toLowerCase()) {
      case 'plumbing':
        latitude = -1.3057;
        longitude = 36.8392;
        break;
      case 'electrical':
        latitude = -1.2734;
        longitude = 36.8919;
        break;
      case 'painting':
        latitude = -1.2297;
        longitude = 36.8969;
        break;
      case 'cleaning':
        latitude = -1.2674;
        longitude = 36.7689;
        break;
      default:
        latitude = -1.2921; // Nairobi center
        longitude = 36.8219;
    }
    Position position = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 1.0,
      headingAccuracy: 1.0,
    );
    setState(() => _currentPosition = position);
    _fetchNearbyProviders(position);
  }

  Future<void> _fetchNearbyProviders(Position position) async {
    try {
      final queryParams = {
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'radius': '5000',
        'serviceType': widget.serviceType.toLowerCase(),
      };

      print('Sending request with parameters: $queryParams');

      final response = await http.get(
        Uri.parse(
          'http://localhost:5000/api/providers/nearby',
        ).replace(queryParameters: queryParams),
      );
      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final providers = json.decode(response.body);
        // Fetch status for each provider
        List<dynamic> enrichedProviders = [];
        for (var provider in providers) {
          final status = await UserStatusService.fetchUserStatus(
            provider['_id'] ?? provider['id'],
          );
          enrichedProviders.add({
            ...provider,
            'isOnline': status?['isOnline'],
            'lastActive': status?['lastActive'],
          });
        }
        setState(() {
          _providers = enrichedProviders;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching providers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nearby Providers')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _providers.length,
              itemBuilder: (context, index) {
                final provider = _providers[index];
                String statusText = provider['isOnline'] == true
                    ? 'Online'
                    : 'Offline';
                String lastActiveText = provider['lastActive'] != null
                    ? 'Last active: ' +
                          DateTime.parse(
                            provider['lastActive'],
                          ).toLocal().toString()
                    : 'Last active: Unknown';
                return Card(
                  child: ListTile(
                    title: Text(
                      provider['businessName'] ?? provider['name'] ?? '',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          lastActiveText,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      provider['isOnline'] == true
                          ? Icons.circle
                          : Icons.circle_outlined,
                      color: provider['isOnline'] == true
                          ? Colors.green
                          : Colors.grey,
                      size: 16,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
