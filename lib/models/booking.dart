import 'package:intl/intl.dart';
import 'dart:math';

enum BookingStatus {
  pending, // Changed to lowercase
  accepted,
  in_progress,
  completed,
  cancelled,
  rejected, // Added missing comma
} // <-- Close the enum with a bracket

extension BookingStatusExtension on BookingStatus {
  String toJson() {
    return toString().split('.').last.toLowerCase(); // Ensure lowercase
  }

  static BookingStatus fromJson(String value) {
    final lowerValue = value.toLowerCase(); // Convert to lowercase
    return BookingStatus.values.firstWhere(
        (status) =>
            status.toString().split('.').last.toLowerCase() == lowerValue,
        orElse: () => BookingStatus.pending);
  }
}

class Service {
  final String name;
  final int quantity;
  final double basePrice;

  Service({
    required this.name,
    required this.quantity,
    required this.basePrice,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      basePrice: (map['basePrice'] ?? 0).toDouble(),
    );
  }
}

class Location {
  final String type;
  final List<double> coordinates;

  Location({required this.type, required this.coordinates});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json['type'] as String,
      coordinates: (json['coordinates'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'coordinates': coordinates,
      };
}

class Payment {
  final String method;
  final String status;
  final String? transactionId;
  final String currency;
  final double amount;

  Payment({
    required this.method,
    required this.status,
    this.transactionId,
    this.currency = 'KES',
    required this.amount,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      method: json['method'] as String,
      status: json['status'] as String,
      transactionId: json['transactionId'] as String?,
      currency: json['currency'] ?? 'KES',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'method': method,
        'status': status,
        'transactionId': transactionId,
        'currency': currency,
        'amount': amount,
      };
}

class Client {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
      };
}

class Booking {
  final String id;
  final String serviceType;
  final DateTime scheduledDate;
  final String status;
  final Map<String, dynamic>? location;
  final Map<String, dynamic> payment;
  final List<Map<String, dynamic>> services;
  final String client;
  final String provider;
  final String notes;
  final DateTime? createdAt;
  final double amount;
  final String? providerName; // Add this if not present

  Booking({
    required this.id,
    required this.serviceType,
    required this.scheduledDate,
    required this.status,
    this.location,
    required this.payment,
    required this.services,
    required this.client,
    required this.provider,
    required this.notes,
    this.createdAt,
    required this.amount,
    this.providerName,
  });

  // Add getters for computed properties
  String get displayName => serviceType;
  String get displayServiceName => serviceType;
  String get displayClientName => client;
  String get clientName => client;
  String get clientPhone => location?['phone'] ?? 'No phone';
  String get displayScheduledTime =>
      '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';
  String get scheduledTime => displayScheduledTime;
  String get displayNotes => notes;

  // Add a safe getter for address
  String get displayAddress {
    if (location == null) return 'No address provided';
    return location!['address']?.toString() ?? 'No address provided';
  }
  // Removed duplicate providerName getter as it conflicts with the providerName field

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'] ?? '',
      serviceType: json['serviceType'] ?? '',
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'])
          : DateTime.now(),
      status: json['status'] ?? 'pending',
      location: json['location'],
      payment: json['payment'] ?? {'status': 'pending', 'method': 'mpesa'},
      services: List<Map<String, dynamic>>.from(json['services'] ?? []),
      client: json['client'] ?? '',
      provider: json['provider'] ?? '',
      notes: json['notes'] ?? '',
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      amount: (json['amount'] ?? 0.0).toDouble(),
      providerName: json['providerName'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceType': serviceType,
      'scheduledDate': scheduledDate.toIso8601String(),
      'status': status,
      'location': location,
      'payment': payment,
      'services': services,
      'client': client,
      'provider': provider,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'amount': amount,
      'providerName': providerName,
    };
  }

  Booking copyWith({
    String? id,
    String? serviceType,
    DateTime? scheduledDate,
    String? status,
    Map<String, dynamic>? location,
    Map<String, dynamic>? payment,
    List<Map<String, dynamic>>? services,
    String? client,
    String? provider,
    String? notes,
    DateTime? createdAt,
    double? amount,
    String? providerName,
  }) {
    return Booking(
      id: id ?? this.id,
      serviceType: serviceType ?? this.serviceType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      location: location ?? this.location,
      payment: payment ?? this.payment,
      services: services ?? this.services,
      client: client ?? this.client,
      provider: provider ?? this.provider,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      amount: amount ?? this.amount,
      providerName: providerName ?? this.providerName,
    );
  }
}
