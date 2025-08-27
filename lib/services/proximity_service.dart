import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../models/service_category.dart';

class ProximityService {
  static final _storage = FlutterSecureStorage(); // No cached baseUrl

  // Add debug logging for all API calls
  static Future<List<ServiceCategory>> getServicesWithRadius({
    double radius = 5.0,
  }) async {
    final url = ApiConfig.getEndpointUrl('services/proximity?radius=$radius');
    print('[ProximityService] GET $url');
    try {
      final response = await http.get(Uri.parse(url));
      print(
        '[ProximityService] Response: ${response.statusCode} ${response.body}',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => ServiceCategory.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load services');
      }
    } catch (e) {
      print('[ProximityService] Error: $e');
      rethrow;
    }
  }

  // Get services with nearby provider counts
  static Future<List<ServiceCategory>> getServicesWithProximity({
    double? latitude,
    double? longitude,
    double radius = 5.0, // km (default 5km)
  }) async {
    try {
      // Get user location if not provided
      if (latitude == null || longitude == null) {
        final position = await _getCurrentLocation();
        latitude = position.latitude;
        longitude = position.longitude;
      }

      final token = await _storage.read(key: 'auth_token');
      print('[ProximityService] Token for proximity request: $token');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };
      print('[ProximityService] Headers for proximity request: $headers');
      final endpoint =
          'services/proximity?lat=$latitude&lng=$longitude&radius=5000';
      print(
        '[ProximityService] About to call ApiConfig.getEndpointUrl with: $endpoint',
      );
      final url = ApiConfig.getEndpointUrl(endpoint);
      print('[ProximityService] GET $url (from endpoint builder)');
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<ServiceCategory> services = [];

        for (var serviceData in data['services']) {
          services.add(ServiceCategory.fromJson(serviceData));
        }

        return services;
      } else {
        // Return default services if API fails
        return _getDefaultServicesWithProximity();
      }
    } catch (e) {
      print('[ProximityService] Error getting services with proximity: $e');
      return _getDefaultServicesWithProximity();
    }
  }

  // Get nearby providers for a specific service
  static Future<List<dynamic>> getNearbyProviders({
    required String serviceType,
    double? latitude,
    double? longitude,
    double radiusKm = 5.0, // Default 5km
  }) async {
    try {
      // Get user location if not provided
      if (latitude == null || longitude == null) {
        final position = await _getCurrentLocation();
        latitude = position.latitude;
        longitude = position.longitude;
      }

      final token = await _storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse(ApiConfig.getEndpointUrl('providers/search/advanced')),
        headers: headers,
        body: json.encode({
          'serviceType': serviceType,
          'location': {'latitude': latitude, 'longitude': longitude},
          'radius': radiusKm,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> &&
            data['data'] != null &&
            data['data']['providers'] != null) {
          return data['data']['providers'] as List<dynamic>;
        } else {
          print('No providers found or unexpected response: $data');
          return [];
        }
      } else {
        print(
          'Error getting nearby providers: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error getting nearby providers: $e');
      return [];
    }
  }

  // Get real-time provider availability
  static Future<Map<String, dynamic>> getProviderAvailability({
    required String serviceId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      if (latitude == null || longitude == null) {
        final position = await _getCurrentLocation();
        latitude = position.latitude;
        longitude = position.longitude;
      }

      final token = await _storage.read(key: 'auth_token');

      final response = await http.get(
        Uri.parse(
          ApiConfig.getEndpointUrl(
            'providers/availability?service=$serviceId&lat=$latitude&lng=$longitude',
          ),
        ),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'availableNow': 5,
          'availableToday': 12,
          'averageWaitTime': 25.0,
          'busyHours': ['9-11', '14-16'],
        };
      }
    } catch (e) {
      print('Error getting provider availability: $e');
      return {
        'availableNow': 5,
        'availableToday': 12,
        'averageWaitTime': 25.0,
        'busyHours': ['9-11', '14-16'],
      };
    }
  }

  // Update user location for better matching
  static Future<bool> updateUserLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');

      final response = await http.put(
        Uri.parse(ApiConfig.getEndpointUrl('users/location')),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating user location: $e');
      return false;
    }
  }

  // Get current location
  static Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Default services with mock proximity data
  static List<ServiceCategory> _getDefaultServicesWithProximity() {
    return [
      ServiceCategory(
        id: 'plumbing',
        name: 'Plumbing',
        icon: Icons.plumbing,
        color: Colors.blue,
        description: 'Water pipes, repairs, installations',
        basePrice: 1500,
        providers: 15,
        nearbyProviders: 7,
        rating: 4.5,
        estimatedTime: '2-4 hours',
        popularService: 'Pipe Installation',
        isAvailable24x7: true,
        averageResponse: 25.0,
        services: [
          'Pipe Installation',
          'Leak Repairs',
          'Drain Cleaning',
          'Water Heater Service',
          'Toilet Installation',
        ],
      ),
      ServiceCategory(
        id: 'electrical',
        name: 'Electrical',
        icon: Icons.electrical_services,
        color: Colors.orange,
        description: 'Wiring, repairs, installations',
        basePrice: 2000,
        providers: 12,
        nearbyProviders: 5,
        rating: 4.7,
        estimatedTime: '1-3 hours',
        popularService: 'Wiring Installation',
        isAvailable24x7: false,
        averageResponse: 20.0,
        services: [
          'Wiring Installation',
          'Socket Repairs',
          'Light Fixtures',
          'Circuit Breaker',
          'Electrical Inspection',
        ],
      ),
      ServiceCategory(
        id: 'cleaning',
        name: 'House Cleaning',
        icon: Icons.cleaning_services,
        color: Colors.green,
        description: 'Professional home & office cleaning',
        basePrice: 800,
        providers: 25,
        nearbyProviders: 12,
        rating: 4.6,
        estimatedTime: '2-6 hours',
        popularService: 'Deep Cleaning',
        isAvailable24x7: false,
        averageResponse: 35.0,
        services: [
          'Deep Cleaning',
          'Regular Cleaning',
          'Move-in/out Cleaning',
          'Office Cleaning',
          'Window Cleaning',
        ],
      ),
      ServiceCategory(
        id: 'painting',
        name: 'Painting',
        icon: Icons.format_paint,
        color: Colors.purple,
        description: 'Interior & exterior painting services',
        basePrice: 1200,
        providers: 8,
        nearbyProviders: 3,
        rating: 4.4,
        estimatedTime: '4-8 hours',
        popularService: 'Interior Painting',
        isAvailable24x7: false,
        averageResponse: 45.0,
        services: [
          'Interior Painting',
          'Exterior Painting',
          'Wall Preparation',
          'Color Consultation',
          'Touch-up Services',
        ],
      ),
      ServiceCategory(
        id: 'pest_control',
        name: 'Pest Control',
        icon: Icons.pest_control,
        color: Colors.red,
        description: 'Complete pest elimination services',
        basePrice: 1000,
        providers: 10,
        nearbyProviders: 4,
        rating: 4.3,
        estimatedTime: '1-2 hours',
        popularService: 'General Pest Control',
        isAvailable24x7: true,
        averageResponse: 30.0,
        services: [
          'General Pest Control',
          'Termite Treatment',
          'Rodent Control',
          'Fumigation',
          'Prevention Treatment',
        ],
      ),
      ServiceCategory(
        id: 'mechanic',
        name: 'Auto Mechanic',
        icon: Icons.car_repair,
        color: Colors.teal,
        description: 'Vehicle repair and maintenance',
        basePrice: 1800,
        providers: 6,
        nearbyProviders: 2,
        rating: 4.2,
        estimatedTime: '2-5 hours',
        popularService: 'Engine Repair',
        isAvailable24x7: false,
        averageResponse: 40.0,
        services: [
          'Engine Repair',
          'Brake Service',
          'Oil Change',
          'Tire Replacement',
          'Battery Replacement',
        ],
      ),
    ];
  }
}
