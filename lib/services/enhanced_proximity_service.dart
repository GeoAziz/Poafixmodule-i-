import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import '../models/service_category_model.dart'; // Only import from models
import '../models/provider_model.dart';
import '../services/api_config.dart';
import '../services/auth_storage.dart';
import '../services/location_service.dart';

class ProximityService {
  static const String _baseUrl = 'http://192.168.0.101:5000/api';
  final AuthStorage _authStorage = AuthStorage();
  final LocationService _locationService = LocationService();

  // Get services with nearby provider counts
  Future<List<ServiceCategoryModel>> getServicesWithProximity({
    double? latitude,
    double? longitude,
    double radiusKm = 5.0, // Increased default radius to 5km
  }) async {
    try {
      Position? position;
      
      // Get current location if not provided
      if (latitude == null || longitude == null) {
        position = await _locationService.getCurrentLocation();
        latitude = position?.latitude ?? -1.2921;  // Default to Nairobi
        longitude = position?.longitude ?? 36.8219;
      }

      final token = await _authStorage.getToken();
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/providers/nearby?serviceType=plumbing'
          '&latitude=$latitude'
          '&longitude=$longitude'
          '&radius=${radiusKm * 1000}' // Convert km to meters for backend
          '&limit=20'
        ),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> servicesJson = data['services'] ?? [];
        
        return servicesJson.map((json) => ServiceCategoryModel.fromJson(json)).toList();
      } else {
        // Return default services if API fails
        return _getDefaultServices();
      }
    } catch (e) {
      print('Error getting proximity services: $e');
      return _getDefaultServices();
    }
  }

  // Get nearby providers for a specific service
  Future<List<ProviderModel>> getNearbyProviders({
    required String serviceType,
    double? latitude,
    double? longitude,
    double radiusKm = 10.0,
    int limit = 20,
  }) async {
    try {
      Position? position;
      
      // Get current location if not provided
      if (latitude == null || longitude == null) {
        position = await _locationService.getCurrentLocation();
        latitude = position?.latitude ?? -1.2921;  // Default to Nairobi
        longitude = position?.longitude ?? 36.8219;
      }

      final token = await _authStorage.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/providers/nearby?serviceType=$serviceType&latitude=$latitude&longitude=$longitude&radius=$radiusKm&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> providersJson = data['providers'] ?? [];
        
        // Always map to ProviderModel
        return providersJson.map((json) {
          final provider = ProviderModel.fromJson(json);
          // Calculate distance if coordinates are available
          if (json['location'] != null && json['location']['coordinates'] != null) {
            final coords = json['location']['coordinates'];
            if (coords.length >= 2) {
              final distance = Geolocator.distanceBetween(
                latitude!,
                longitude!,
                coords[1].toDouble(),
                coords[0].toDouble(),
              ) / 1000; // Convert to km

              // Add distance info to metadata only
              provider.metadata['distance'] = distance.toStringAsFixed(1);
              provider.metadata['distanceKm'] = distance;
            }
          }
          return provider;
        }).toList();
      } else {
        throw Exception('Failed to fetch nearby providers');
      }
    } catch (e) {
      print('Error getting nearby providers: $e');
      return [];
    }
  }

  // Get provider count for a specific service in area
  Future<int> getProviderCount({
    required String serviceType,
    double? latitude,
    double? longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      Position? position;
      
      if (latitude == null || longitude == null) {
        position = await _locationService.getCurrentLocation();
        latitude = position?.latitude ?? -1.2921;
        longitude = position?.longitude ?? 36.8219;
      }

      final token = await _authStorage.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/providers/count?service=$serviceType&lat=$latitude&lng=$longitude&radius=$radiusKm'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      print('Error getting provider count: $e');
      return 0;
    }
  }

  // Update location and refresh proximity data
  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      final token = await _authStorage.getToken();
      await http.post(
        Uri.parse('$_baseUrl/user/location'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  // Get default services (fallback)
  List<ServiceCategoryModel> _getDefaultServices() {
    return [
      ServiceCategoryModel(
        id: 'plumbing',
        name: 'Plumbing',
        icon: Icons.plumbing,
        color: Colors.blue,
        description: 'Water pipes, repairs, installations',
        basePrice: 1500,
        nearbyProviders: 12,
        rating: 4.5,
        estimatedTime: '2-4 hours',
        subServices: const [
          'Pipe Installation',
          'Leak Repairs',
          'Drain Cleaning',
          'Water Heater Service',
          'Toilet Installation',
          'Faucet Repair',
        ],
        image: '',
        isPopular: true,
        avgDistance: 2.3,
      ),
      ServiceCategoryModel(
        id: 'electrical',
        name: 'Electrical',
        icon: Icons.electrical_services,
        color: Colors.orange,
        description: 'Wiring, repairs, installations',
        basePrice: 2000,
        nearbyProviders: 8,
        rating: 4.7,
        estimatedTime: '1-3 hours',
        subServices: const [
          'Wiring Installation',
          'Socket Repairs',
          'Light Fixtures',
          'Circuit Breaker',
          'Electrical Inspection',
          'Smart Home Setup',
        ],
        image: '',
        isPopular: true,
        avgDistance: 1.8,
      ),
      ServiceCategoryModel(
        id: 'cleaning',
        name: 'House Cleaning',
        icon: Icons.cleaning_services,
        color: Colors.green,
        description: 'Professional home & office cleaning',
        basePrice: 800,
        nearbyProviders: 25,
        rating: 4.6,
        estimatedTime: '2-6 hours',
        subServices: const [
          'Deep Cleaning',
          'Regular Cleaning',
          'Move-in/out Cleaning',
          'Office Cleaning',
          'Window Cleaning',
          'Carpet Cleaning',
        ],
        image: '',
        isPopular: true,
        avgDistance: 1.2,
      ),
      ServiceCategoryModel(
        id: 'painting',
        name: 'Painting',
        icon: Icons.format_paint,
        color: Colors.purple,
        description: 'Interior & exterior painting services',
        basePrice: 1200,
        nearbyProviders: 6,
        rating: 4.4,
        estimatedTime: '4-8 hours',
        subServices: const [
          'Interior Painting',
          'Exterior Painting',
          'Wall Preparation',
          'Color Consultation',
          'Touch-up Services',
          'Decorative Painting',
        ],
        image: '',
        isPopular: false,
        avgDistance: 3.1,
      ),
      ServiceCategoryModel(
        id: 'pest_control',
        name: 'Pest Control',
        icon: Icons.pest_control,
        color: Colors.red,
        description: 'Professional pest elimination',
        basePrice: 1800,
        nearbyProviders: 4,
        rating: 4.3,
        estimatedTime: '1-2 hours',
        subServices: const [
          'Termite Control',
          'Rodent Control',
          'Cockroach Treatment',
          'Ant Control',
          'Fumigation',
          'Preventive Treatment',
        ],
        image: '',
        isPopular: false,
        avgDistance: 4.2,
      ),
      ServiceCategoryModel(
        id: 'mechanic',
        name: 'Auto Mechanic',
        icon: Icons.car_repair,
        color: Colors.teal,
        description: 'Vehicle repair and maintenance',
        basePrice: 2500,
        nearbyProviders: 10,
        rating: 4.2,
        estimatedTime: '2-6 hours',
        subServices: const [
          'Engine Repair',
          'Brake Service',
          'Oil Change',
          'Tire Replacement',
          'Battery Service',
          'AC Repair',
        ],
        image: '',
        isPopular: false,
        avgDistance: 2.8,
      ),
    ];
  }
}
