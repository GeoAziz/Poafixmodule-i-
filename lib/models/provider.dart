class Provider {
  final String id; // Changed from int to String
  final String name;
  final double rating;
  final double latitude;
  final double longitude;
  final double distance;
  final bool isAvailable;

  Provider({
    required this.id,
    required this.name,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.isAvailable = true,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    final location = json['location']['coordinates'];
    return Provider(
      id: json['_id'].toString(), // Keep as string
      name: json['name'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      latitude: location[1],
      longitude: location[0],
      distance: json['distance']?.toDouble() ?? 0.0,
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rating': rating,
        'latitude': latitude,
        'longitude': longitude,
        'distance': distance,
        'isAvailable': isAvailable,
      };
}
