import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ServiceProviderListScreen extends StatefulWidget {
  final String serviceType;

  const ServiceProviderListScreen({
    super.key,
    required this.serviceType,
  });

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

      final uri = Uri.parse('http://localhost:5000/api/location/nearby')
          .replace(queryParameters: queryParams);

      print('Request URL: $uri');

      final response = await http.get(uri);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _providers = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load providers: ${response.body}');
      }
    } catch (e) {
      print('Error fetching providers: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _providers.length,
      itemBuilder: (context, index) {
        final provider = _providers[index];
        return ListTile(
          title: Text(provider['name'] ?? 'Unknown Provider'),
          subtitle:
              Text('Distance: ${provider['distance']?.toStringAsFixed(2)} km'),
          trailing: ElevatedButton(
            onPressed: () {
              // Handle booking
            },
            child: Text('Book'),
          ),
        );
      },
    );
  }
}
