import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/api_config.dart';

class LocationService {
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  Timer? _locationTimer;
  Position? _lastKnownPosition;
  static const String _savedLocationsKey = 'saved_locations';

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Future<void> startLocationUpdates(String serviceProviderId) async {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
      final position = await getCurrentLocation();
      if (position != null) {
        await updateLocationOnServer(serviceProviderId, position);
      }
    });
  }

  Future<void> updateLocationOnServer(
      String serviceProviderId, Position position) async {
    if (_lastKnownPosition?.latitude == position.latitude &&
        _lastKnownPosition?.longitude == position.longitude) {
      return; // Skip if location hasn't changed
    }

    _lastKnownPosition = position;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/location/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'serviceProviderId': serviceProviderId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to update location: ${response.body}');
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  void stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  void dispose() {
    stopLocationUpdates();
  }

  Future<bool> updateLocation() async {
    try {
      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get service provider ID from secure storage
      final String? serviceProviderId = await _storage.read(key: 'userId');
      if (serviceProviderId == null) {
        throw Exception('Service provider ID not found');
      }

      // Make API request to update location
      final response = await http.post(
        Uri.parse('$baseUrl/location/update'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'serviceProviderId': serviceProviderId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        print('Location updated successfully');
        return true;
      } else {
        print('Failed to update location: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating location: $e');
      return false;
    }
  }

  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<List<dynamic>> getNearbyProviders(double latitude, double longitude,
      {double radius = 5000}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/nearby').replace(queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'radius': radius.toString(),
        }),
      );

      print('Location API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to load providers: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      print('Error in location service: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProviderLocation(
    String providerId,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/location/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'providerId': providerId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update location: ${response.body}');
      }
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }

  Future<void> updateProviderLocationWithAuth(
      String providerId, Map<String, dynamic> locationData) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      // Update URL to match server routes
      final String url = '$baseUrl/providers/$providerId/location';
      print('DEBUG: Sending location update to: $url');
      print('DEBUG: Request body: ${json.encode(locationData)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(locationData),
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 404) {
        print('DEBUG: Attempting fallback URL...');
        // Try fallback URL with /api prefix
        final fallbackUrl = '$baseUrl/api/providers/$providerId/location';
        final fallbackResponse = await http.post(
          Uri.parse(fallbackUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(locationData),
        );

        if (fallbackResponse.statusCode != 200) {
          throw Exception(
              'Location update failed: ${fallbackResponse.statusCode} - ${fallbackResponse.body}');
        }
      } else if (response.statusCode != 200) {
        throw Exception(
            'Location update failed: ${response.statusCode} - ${response.body}');
      }

      print('DEBUG: Location update successful');
    } catch (e) {
      print('DEBUG: Location update error: $e');
      rethrow;
    }
  }

  static Future<Map<String, double>> getCoordinatesFromAddress(
      String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=YOUR_GOOGLE_MAPS_API_KEY';

      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['results'] != null && data['results'].length > 0) {
        final location = data['results'][0]['geometry']['location'];
        return {
          'latitude': location['lat'],
          'longitude': location['lng'],
        };
      }

      return {
        'latitude': -1.2921,
        'longitude': 36.8219,
      };
    } catch (e) {
      print('Error getting coordinates: $e');
      return {
        'latitude': -1.2921,
        'longitude': 36.8219,
      };
    }
  }

  Future<void> updateProviderLocationStatus({
    required String providerId,
    required double latitude,
    required double longitude,
    required bool isOnline,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/providers/$providerId/location'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'location': {
            'type': 'Point',
            'coordinates': [longitude, latitude]
          },
          'isAvailable': isOnline,
          'lastUpdated': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update location: ${response.body}');
      }
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }

  Future<void> updateLocationWithAvailability({
    required String providerId,
    required double latitude,
    required double longitude,
    required bool isOnline,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/providers/location'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'providerId': providerId,
          'location': {
            'type': 'Point',
            'coordinates': [longitude, latitude]
          },
          'isAvailable': isOnline,
          'lastUpdated': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update location: ${response.body}');
      }
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 5),
    );
  }

  // Add method to calculate distance between two points
  double calculateDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  Future<void> saveLocation({
    required String name,
    required String address,
    required LatLng coordinates,
    String? type,
  }) async {
    try {
      final locations = await getSavedLocations();

      locations.add({
        'name': name,
        'address': address,
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
        'type': type ?? 'custom',
        'timestamp': DateTime.now().toIso8601String(),
      });

      await _storage.write(
        key: _savedLocationsKey,
        value: json.encode(locations),
      );
    } catch (e) {
      print('Error saving location: $e');
      rethrow;
    }
  }

  Future<void> saveLocations(List<Map<String, dynamic>> locations) async {
    try {
      await _storage.write(
        key: _savedLocationsKey,
        value: json.encode(locations),
      );
    } catch (e) {
      print('Error saving locations: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSavedLocations() async {
    try {
      final data = await _storage.read(key: _savedLocationsKey);
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(json.decode(data));
    } catch (e) {
      print('Error getting saved locations: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/places/$placeId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to get place details');
  }

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/places/search?query=$query'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['predictions']);
    }
    throw Exception('Failed to search places');
  }

  // Remove static from these methods and make them instance methods
  Future<bool> hasLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<bool> requestLocationPermissionHelper() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentLocationHelper() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
}
