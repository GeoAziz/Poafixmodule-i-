class ProviderLocation {
  final String providerId;
  final double latitude;
  final double longitude;
  final DateTime lastUpdated;
  final bool isOnline;
  final Map<String, dynamic> availability;

  ProviderLocation({
    required this.providerId,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
    required this.isOnline,
    required this.availability,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isOnline': isOnline,
      'availability': availability,
    };
  }

  factory ProviderLocation.fromMap(Map<String, dynamic> map, String id) {
    return ProviderLocation(
      providerId: id,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      lastUpdated: DateTime.parse(map['lastUpdated']),
      isOnline: map['isOnline'] as bool,
      availability: map['availability'] as Map<String, dynamic>,
    );
  }
}
