import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'booking/booking_screen.dart';
import 'package:lottie/lottie.dart' as lottie;
import '../services/provider_service.dart';

class ServiceProviderListScreen extends StatefulWidget {
  final String serviceType;
  final List<Map<String, dynamic>> selectedServices;
  final LatLng initialLocation;
  final String clientId;

  const ServiceProviderListScreen({
    super.key,
    required this.serviceType,
    required this.selectedServices,
    required this.initialLocation,
    required this.clientId,
  });

  @override
  _ServiceProviderListScreenState createState() =>
      _ServiceProviderListScreenState();
}

class _ServiceProviderListScreenState extends State<ServiceProviderListScreen> {
  List<Map<String, dynamic>> providers = [];
  bool isLoading = true;
  String? error;
  final Set<Marker> _markers = {};
  late GoogleMapController _mapController;
  bool _isMapReady = false;
  double _maxDistance = 5000;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      print('DEBUG: Loading providers with params:');
      print(
        'Location: ${widget.initialLocation.latitude}, ${widget.initialLocation.longitude}',
      );
      print('Service: ${widget.serviceType}');
      print('Radius: $_maxDistance');

      final fetchedProviders = await ProviderService.getNearbyProviders(
        serviceType: widget.serviceType.toLowerCase(), // Important: lowercase
        location: {
          'lat': widget.initialLocation.latitude,
          'lng': widget.initialLocation.longitude,
        },
        radius: _maxDistance,
      );

      if (mounted) {
        setState(() {
          providers = List<Map<String, dynamic>>.from(fetchedProviders);
          isLoading = false;
          if (providers.isNotEmpty) {
            _updateMapMarkers();
          }
        });
      }
    } catch (e) {
      print('ERROR loading providers: $e');
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
          providers = [];
        });
      }
    }
  }

  void _updateMapMarkers() {
    if (!mounted) return;

    try {
      _markers.clear();
      for (var provider in providers) {
        if (provider['location'] == null ||
            provider['location']['coordinates'] == null) {
          print(
            'Invalid location data for provider: ${provider['businessName']}',
          );
          continue;
        }

        final coordinates = provider['location']['coordinates'] as List;
        final position = LatLng(
          coordinates[1] as double, // Latitude is second
          coordinates[0] as double, // Longitude is first
        );

        _markers.add(
          Marker(
            markerId: MarkerId(provider['_id'].toString()),
            position: position,
            infoWindow: InfoWindow(
              title: provider['businessName'] ?? provider['name'] ?? 'Unknown',
              snippet: 'Rating: ${provider['rating']?.toStringAsFixed(1)} ★',
            ),
          ),
        );
      }

      print('Added ${_markers.length} markers to the map');
      if (_isMapReady && _markers.isNotEmpty) {
        _fitBoundsToMarkers();
      }
    } catch (e) {
      print('Error updating markers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Available ${widget.serviceType} Providers')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMap(),
                Expanded(
                  child: providers.isEmpty
                      ? _buildEmptyState()
                      : _buildProvidersList(),
                ),
              ],
            ),
    );
  }

  Widget _buildMap() {
    return SizedBox(
      height: 300,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            widget.initialLocation.latitude,
            widget.initialLocation.longitude,
          ),
          zoom: 13,
        ),
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
          _isMapReady = true;
          _fitBoundsToMarkers();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          lottie.Lottie.asset(
            'assets/animations/no_results.json',
            width: 200,
            height: 200,
          ),
          Text(
            'No providers found in your area',
            style: TextStyle(fontSize: 18),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _maxDistance += 5000);
              _loadProviders();
            },
            child: Text('Search Wider Area'),
          ),
        ],
      ),
    );
  }

  Widget _buildProvidersList() {
    return ListView.builder(
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(child: Text(provider['name']?[0] ?? 'P')),
            title: Text(
              provider['businessName'] ?? provider['name'] ?? 'Unknown',
            ),
            subtitle: Text(
              'Rating: ${provider['rating']?.toStringAsFixed(1)} ★',
            ),
            trailing: ElevatedButton(
              onPressed: () => _onBookPressed(provider),
              child: Text('Book'),
            ),
          ),
        );
      },
    );
  }

  void _onBookPressed(Map<String, dynamic> provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          provider: provider,
          serviceOffered: widget.serviceType,
          selectedServices: widget.selectedServices,
          clientId: widget.clientId,
          providerName:
              provider['businessName'] ?? provider['name'] ?? 'Unknown',
          providerId: provider['_id'],
        ),
      ),
    );
  }

  void _fitBoundsToMarkers() {
    if (!_isMapReady || providers.isEmpty) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (var provider in providers) {
      final lat = provider['location']['coordinates'][1] as double;
      final lng = provider['location']['coordinates'][0] as double;

      minLat = min(minLat, lat);
      maxLat = max(maxLat, lat);
      minLng = min(minLng, lng);
      maxLng = max(maxLng, lng);
    }

    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }
}
