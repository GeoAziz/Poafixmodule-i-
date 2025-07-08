import 'package:flutter/material.dart';
import '../service_provider_list_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MovingScreen extends StatefulWidget {
  @override
  _MovingScreenState createState() => _MovingScreenState();
}

class _MovingScreenState extends State<MovingScreen> {
  final _storage = const FlutterSecureStorage();
  String? _selectedService;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = position);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _navigateToProviderList() async {
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a service type')));
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Getting your location...')));
      await _getCurrentLocation();
      if (_currentPosition == null) return;
    }

    final clientId = await _storage.read(key: 'userId');
    if (clientId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please login first')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceProviderListScreen(
          clientId: clientId,
          serviceType: 'moving',
          selectedServices: [
            {'service': _selectedService!}
          ],
          initialLocation: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Moving Services')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: _selectedService,
              hint: Text('Select a service'),
              items: ['Local Moving', 'Long Distance', 'Packing', 'Storage']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedService = newValue;
                });
              },
            ),
            ElevatedButton(
              onPressed: _navigateToProviderList,
              child: Text('Find Service Providers'),
            ),
          ],
        ),
      ),
    );
  }
}
