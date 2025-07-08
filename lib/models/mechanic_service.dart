class MechanicService {
  final String id;
  final String name;
  final String iconUrl;
  final String color;
  final double basePrice;
  final bool allowMultiple;
  int quantity;
  final String description;

  MechanicService({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.color,
    required this.basePrice,
    this.allowMultiple = false,
    this.quantity = 0,
    required this.description,
  });

  factory MechanicService.fromJson(Map<String, dynamic> json) {
    return MechanicService(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      iconUrl:
          json['iconUrl'] ?? 'https://img.icons8.com/color/96/maintenance.png',
      color: json['color'] ?? '#FF5722',
      basePrice: json['basePrice']?.toDouble() ?? 0.0,
      allowMultiple: json['allowMultiple'] ?? false,
      description: json['description'] ?? '',
    );
  }
}
