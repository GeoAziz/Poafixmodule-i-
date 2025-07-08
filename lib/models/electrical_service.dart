class ElectricalService {
  final String id;
  final String name;
  final String description;
  final String imageUrl; // Changed from icon to imageUrl
  final double basePrice;
  final String color;
  final bool allowMultiple;
  int quantity;

  ElectricalService({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.basePrice,
    required this.color,
    required this.allowMultiple,
    this.quantity = 0,
  });

  factory ElectricalService.fromJson(Map<String, dynamic> json) {
    return ElectricalService(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      basePrice: json['basePrice'].toDouble(),
      color: json['color'],
      allowMultiple: json['allowMultiple'],
    );
  }
}
