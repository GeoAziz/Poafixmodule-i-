import 'package:flutter/material.dart';

class ServiceCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final double basePrice;
  final int providers;
  final double rating;
  final String estimatedTime;
  final List<String> services;
  final int nearbyProviders;
  final String popularService;
  final bool isAvailable24x7;
  final double averageResponse;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.basePrice,
    required this.providers,
    required this.rating,
    required this.estimatedTime,
    required this.services,
    this.nearbyProviders = 0,
    this.popularService = '',
    this.isAvailable24x7 = false,
    this.averageResponse = 30.0,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: _getIconFromString(json['icon'] ?? 'build'),
      color: _getColorFromString(json['color'] ?? 'blue'),
      description: json['description'] ?? '',
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      providers: json['providers'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      estimatedTime: json['estimatedTime'] ?? '',
      services: List<String>.from(json['services'] ?? []),
      nearbyProviders: json['nearbyProviders'] ?? 0,
      popularService: json['popularService'] ?? '',
      isAvailable24x7: json['isAvailable24x7'] ?? false,
      averageResponse: (json['averageResponse'] ?? 30).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint.toString(),
      'color': color.value.toString(),
      'description': description,
      'basePrice': basePrice,
      'providers': providers,
      'rating': rating,
      'estimatedTime': estimatedTime,
      'services': services,
      'nearbyProviders': nearbyProviders,
      'popularService': popularService,
      'isAvailable24x7': isAvailable24x7,
      'averageResponse': averageResponse,
    };
  }

  static IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'format_paint':
        return Icons.format_paint;
      case 'pest_control':
        return Icons.pest_control;
      case 'build':
        return Icons.build;
      case 'car_repair':
        return Icons.car_repair;
      case 'home_repair_service':
        return Icons.home_repair_service;
      default:
        return Icons.build;
    }
  }

  static Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      case 'teal':
        return Colors.teal;
      case 'amber':
        return Colors.amber;
      case 'indigo':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }
}
