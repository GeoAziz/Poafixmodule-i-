import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ServiceProviderListScreen extends StatefulWidget {
  final String serviceType;

  const ServiceProviderListScreen({
    Key? key,
    required this.serviceType,
  }) : super(key: key);

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
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentPosition = position);
      _fetchNearbyProviders(position);
    } catch (e) {
      print('Error getting location: $e');
    }
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
