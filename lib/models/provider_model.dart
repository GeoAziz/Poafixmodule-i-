class ProviderModel {
  final String id;
  final String name;
  final String? email; // Add this field
  final String? phoneNumber; // Add this field
  final String? businessName; // Add this field
  final String? serviceType; // Add this field
  final String? profileImage;
  final double? rating;
  final int? totalRatings;
  final int? completedJobs;
  final double? hourlyRate;
  final bool isVerified;
  final double? distance;
  final Map<String, dynamic> metadata;
  final Location location;
  final bool isAvailable;
  final String status;
  final DateTime lastUpdated;
  final String? description; // Add this field
  final List<String>? skills; // Add this field
  final int? experience; // Add this field
  final String? portfolio; // Add this field
  final dynamic availability; // Accepts both List and Map

  ProviderModel({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.businessName,
    this.serviceType,
    this.profileImage,
    this.rating,
    this.totalRatings,
    this.completedJobs,
    this.hourlyRate,
    this.isVerified = false,
    this.distance,
    this.metadata = const {},
    required this.location,
    required this.isAvailable,
    required this.status,
    required this.lastUpdated,
    this.description,
    this.skills,
    this.experience,
    this.portfolio,
    this.availability,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return ProviderModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      businessName: json['businessName'],
      serviceType: json['serviceType'],
      profileImage: json['profileImage'],
      rating: (json['rating'] as num?)?.toDouble(),
      totalRatings: parseInt(json['totalRatings']),
      completedJobs: parseInt(json['completedJobs']),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      isVerified: json['isVerified'] ?? false,
      distance: (json['distance'] as num?)?.toDouble(),
      metadata: json['metadata'] ?? {},
      location: Location.fromJson(json['location'] ?? {}),
      isAvailable: json['isAvailable'] ?? false,
      status: json['status'] ?? 'offline',
      lastUpdated: DateTime.parse(
          json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      description: json['description'],
      skills: (json['skills'] as List?)?.map((e) => e.toString()).toList(),
      experience: parseInt(json['experience']),
      portfolio: json['portfolio'],
      availability: json['availability'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'businessName': businessName,
      'serviceType': serviceType,
      'profileImage': profileImage,
      'rating': rating,
      'totalRatings': totalRatings,
      'completedJobs': completedJobs,
      'hourlyRate': hourlyRate,
      'isVerified': isVerified,
      'distance': distance,
      'metadata': metadata,
      'location': location.toJson(),
      'isAvailable': isAvailable,
      'status': status,
      'lastUpdated': lastUpdated.toIso8601String(),
      'description': description,
      'skills': skills,
      'experience': experience,
      'portfolio': portfolio,
      'availability': availability,
    };
  }
}

class Location {
  final String type;
  final List<double> coordinates;

  Location({
    required this.type,
    required this.coordinates,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json['type'] ?? 'Point',
      coordinates: List<double>.from(json['coordinates'] ?? [0.0, 0.0]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }

  double get latitude => coordinates[1];
  double get longitude => coordinates[0];
}
