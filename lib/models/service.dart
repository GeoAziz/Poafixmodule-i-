class Service {
  final String id;
  final String providerId;
  final String name;
  final String category;
  final double basePrice;
  final String description;
  final bool isAvailable;
  final List<String> images;
  final Map<String, dynamic> pricing;
  final List<String> features;
  final double rating;
  final int totalRatings;

  Service({
    required this.id,
    required this.providerId,
    required this.name,
    required this.category,
    required this.basePrice,
    this.description = '',
    this.isAvailable = true,
    this.images = const [],
    this.pricing = const {},
    this.features = const [],
    this.rating = 0.0,
    this.totalRatings = 0,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['_id'] ?? '',
      providerId: json['providerId'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      basePrice: (json['basePrice'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      images: List<String>.from(json['images'] ?? []),
      pricing: json['pricing'] ?? {},
      features: List<String>.from(json['features'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
    );
  }
}
