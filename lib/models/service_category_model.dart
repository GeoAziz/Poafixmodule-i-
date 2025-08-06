import 'package:flutter/material.dart';

class ServiceCategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final double basePrice;
  final int nearbyProviders;
  final double rating;
  final String estimatedTime;
  final List<String> subServices;
  final String image;
  final bool isPopular;
  final double avgDistance;

  ServiceCategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.basePrice,
    required this.nearbyProviders,
    required this.rating,
    required this.estimatedTime,
    required this.subServices,
    this.image = '',
    this.isPopular = false,
    this.avgDistance = 0.0,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: _getIconFromString(json['icon'] ?? 'build'),
      color: _getColorFromString(json['color'] ?? 'blue'),
      description: json['description'] ?? '',
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      nearbyProviders: json['nearbyProviders'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      estimatedTime: json['estimatedTime'] ?? '',
      subServices: List<String>.from(json['subServices'] ?? []),
      image: json['image'] ?? '',
      isPopular: json['isPopular'] ?? false,
      avgDistance: (json['avgDistance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.toString(),
      'color': color.toString(),
      'description': description,
      'basePrice': basePrice,
      'nearbyProviders': nearbyProviders,
      'rating': rating,
      'estimatedTime': estimatedTime,
      'subServices': subServices,
      'image': image,
      'isPopular': isPopular,
      'avgDistance': avgDistance,
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
      case 'hvac':
        return Icons.thermostat;
      default:
        return Icons.home_repair_service;
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
      case 'indigo':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }
}
