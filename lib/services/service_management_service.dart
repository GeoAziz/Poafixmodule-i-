import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/service_history_model.dart';
import '../models/recurring_booking_model.dart';
import '../models/service_package_model.dart';
import 'api_config.dart';

class ServiceManagementService {
  static final ServiceManagementService _instance = ServiceManagementService._internal();
  factory ServiceManagementService() => _instance;
  ServiceManagementService._internal();

  final _storage = const FlutterSecureStorage();

  // Service History Management
  Future<List<ServiceHistoryModel>> getServiceHistory({
    String? userId,
    String? serviceType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (userId != null) queryParams['userId'] = userId;
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final uri = Uri.parse('${ApiConfig.baseUrl}/service-history').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((history) => ServiceHistoryModel.fromJson(history))
            .toList();
      }
      throw Exception('Failed to load service history');
    } catch (e) {
      throw Exception('Error loading service history: $e');
    }
  }

  Future<ServiceHistoryModel> getServiceHistoryById(String historyId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/service-history/$historyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ServiceHistoryModel.fromJson(data['data']);
      }
      throw Exception('Failed to load service history details');
    } catch (e) {
      throw Exception('Error loading service history details: $e');
    }
  }

  Future<Map<String, dynamic>> getServiceHistoryAnalytics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final queryParams = <String, String>{};

      if (userId != null) queryParams['userId'] = userId;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final uri = Uri.parse('${ApiConfig.baseUrl}/service-history/analytics').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      throw Exception('Failed to load analytics');
    } catch (e) {
      throw Exception('Error loading analytics: $e');
    }
  }

  // Recurring Bookings Management
  Future<List<RecurringBookingModel>> getRecurringBookings({
    String? userId,
    bool? isActive,
    String? serviceType,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final queryParams = <String, String>{};

      if (userId != null) queryParams['userId'] = userId;
      if (isActive != null) queryParams['isActive'] = isActive.toString();
      if (serviceType != null) queryParams['serviceType'] = serviceType;

      final uri = Uri.parse('${ApiConfig.baseUrl}/recurring-bookings').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((booking) => RecurringBookingModel.fromJson(booking))
            .toList();
      }
      throw Exception('Failed to load recurring bookings');
    } catch (e) {
      throw Exception('Error loading recurring bookings: $e');
    }
  }

  Future<RecurringBookingModel> createRecurringBooking({
    required String providerId,
    required String serviceType,
    required String serviceName,
    required Map<String, dynamic> serviceDetails,
    required RecurrencePattern recurrencePattern,
    required DateTime startDate,
    DateTime? endDate,
    int? maxOccurrences,
    required double amount,
    required String paymentMethod,
    required Map<String, dynamic> location,
    String notes = '',
    Map<String, dynamic> preferences = const {},
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/recurring-bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'providerId': providerId,
          'serviceType': serviceType,
          'serviceName': serviceName,
          'serviceDetails': serviceDetails,
          'recurrencePattern': recurrencePattern.toJson(),
          'startDate': startDate.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
          'maxOccurrences': maxOccurrences,
          'amount': amount,
          'paymentMethod': paymentMethod,
          'location': location,
          'notes': notes,
          'preferences': preferences,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return RecurringBookingModel.fromJson(data['data']);
      }
      throw Exception('Failed to create recurring booking');
    } catch (e) {
      throw Exception('Error creating recurring booking: $e');
    }
  }

  Future<RecurringBookingModel> updateRecurringBooking(
    String recurringBookingId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/recurring-bookings/$recurringBookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RecurringBookingModel.fromJson(data['data']);
      }
      throw Exception('Failed to update recurring booking');
    } catch (e) {
      throw Exception('Error updating recurring booking: $e');
    }
  }

  Future<void> cancelRecurringBooking(String recurringBookingId, {String? reason}) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/recurring-bookings/$recurringBookingId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'reason': reason,
        }),
      );
    } catch (e) {
      throw Exception('Error cancelling recurring booking: $e');
    }
  }

  Future<void> pauseRecurringBooking(String recurringBookingId, {DateTime? resumeDate}) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/recurring-bookings/$recurringBookingId/pause'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'resumeDate': resumeDate?.toIso8601String(),
        }),
      );
    } catch (e) {
      throw Exception('Error pausing recurring booking: $e');
    }
  }

  // Service Packages Management
  Future<List<ServicePackageModel>> getServicePackages({
    String? providerId,
    String? category,
    PackageType? type,
    bool? isActive,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final queryParams = <String, String>{};

      if (providerId != null) queryParams['providerId'] = providerId;
      if (category != null) queryParams['category'] = category;
      if (type != null) queryParams['type'] = type.toString().split('.').last;
      if (isActive != null) queryParams['isActive'] = isActive.toString();
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();

      final uri = Uri.parse('${ApiConfig.baseUrl}/service-packages').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((package) => ServicePackageModel.fromJson(package))
            .toList();
      }
      throw Exception('Failed to load service packages');
    } catch (e) {
      throw Exception('Error loading service packages: $e');
    }
  }

  Future<ServicePackageModel> getServicePackageById(String packageId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/service-packages/$packageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ServicePackageModel.fromJson(data['data']);
      }
      throw Exception('Failed to load service package');
    } catch (e) {
      throw Exception('Error loading service package: $e');
    }
  }

  Future<ServicePackageModel> createServicePackage({
    required String name,
    required String description,
    required String category,
    required List<ServicePackageItem> services,
    required double packagePrice,
    required PackageType type,
    required Duration validity,
    int maxBookings = 1,
    List<String> features = const [],
    List<String> limitations = const [],
    List<String> images = const [],
    Map<String, dynamic> terms = const {},
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/service-packages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'description': description,
          'category': category,
          'services': services.map((service) => service.toJson()).toList(),
          'packagePrice': packagePrice,
          'type': type.toString().split('.').last,
          'validityDays': validity.inDays,
          'maxBookings': maxBookings,
          'features': features,
          'limitations': limitations,
          'images': images,
          'terms': terms,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ServicePackageModel.fromJson(data['data']);
      }
      throw Exception('Failed to create service package');
    } catch (e) {
      throw Exception('Error creating service package: $e');
    }
  }

  Future<Map<String, dynamic>> bookServicePackage({
    required String packageId,
    required DateTime scheduledDate,
    required Map<String, dynamic> location,
    String? notes,
    Map<String, dynamic> customizations = const {},
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/service-packages/$packageId/book'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'scheduledDate': scheduledDate.toIso8601String(),
          'location': location,
          'notes': notes,
          'customizations': customizations,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      }
      throw Exception('Failed to book service package');
    } catch (e) {
      throw Exception('Error booking service package: $e');
    }
  }

  // Utility methods
  Future<List<String>> getServiceCategories() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/service-categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['data']);
      }
      throw Exception('Failed to load service categories');
    } catch (e) {
      throw Exception('Error loading service categories: $e');
    }
  }

  Future<Map<String, dynamic>> getServiceAnalytics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final queryParams = <String, String>{};

      if (userId != null) queryParams['userId'] = userId;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final uri = Uri.parse('${ApiConfig.baseUrl}/service-analytics').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      throw Exception('Failed to load service analytics');
    } catch (e) {
      throw Exception('Error loading service analytics: $e');
    }
  }
}