class ProviderModel {
  final String id;
  final String name;
  final Location location;
  final bool isAvailable;
  final String status;
  final DateTime lastUpdated;

  ProviderModel({
    required this.id,
    required this.name,
    required this.location,
    required this.isAvailable,
    required this.status,
    required this.lastUpdated,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      location: Location.fromJson(json['location'] ?? {}),
      isAvailable: json['isAvailable'] ?? false,
      status: json['status'] ?? 'offline',
      lastUpdated: DateTime.parse(
          json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'location': location.toJson(),
      'isAvailable': isAvailable,
      'status': status,
      'lastUpdated': lastUpdated.toIso8601String(),
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
