class ServicePackageModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<ServicePackageItem> services;
  final double packagePrice;
  final PackageType type;
  final Duration validity;
  final int maxBookings;
  final List<String> features;
  final List<String> limitations;
  final List<String> images;
  final Map<String, dynamic> terms;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ServicePackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.services,
    required this.packagePrice,
    required this.type,
    required this.validity,
    this.maxBookings = 1,
    this.features = const [],
    this.limitations = const [],
    this.images = const [],
    this.terms = const {},
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory ServicePackageModel.fromJson(Map<String, dynamic> json) {
    return ServicePackageModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      services: (json['services'] as List<dynamic>?)
          ?.map((item) => ServicePackageItem.fromJson(item))
          .toList() ?? [],
      packagePrice: (json['packagePrice'] ?? 0.0).toDouble(),
      type: PackageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => PackageType.standard,
      ),
      validity: Duration(days: json['validityDays'] ?? 30),
      maxBookings: json['maxBookings'] ?? 1,
      features: List<String>.from(json['features'] ?? []),
      limitations: List<String>.from(json['limitations'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      terms: json['terms'] ?? {},
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'services': services.map((item) => item.toJson()).toList(),
      'packagePrice': packagePrice,
      'type': type.toString().split('.').last,
      'validityDays': validity.inDays,
      'maxBookings': maxBookings,
      'features': features,
      'limitations': limitations,
      'images': images,
      'terms': terms,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class ServicePackageItem {
  final String serviceId;
  final String serviceName;
  final String description;
  final double originalPrice;
  final double packagePrice;
  final int quantity;
  final Duration estimatedDuration;
  final List<String> requirements;

  ServicePackageItem({
    required this.serviceId,
    required this.serviceName,
    required this.description,
    required this.originalPrice,
    required this.packagePrice,
    this.quantity = 1,
    required this.estimatedDuration,
    this.requirements = const [],
  });

  factory ServicePackageItem.fromJson(Map<String, dynamic> json) {
    return ServicePackageItem(
      serviceId: json['serviceId'] ?? '',
      serviceName: json['serviceName'] ?? '',
      description: json['description'] ?? '',
      originalPrice: (json['originalPrice'] ?? 0.0).toDouble(),
      packagePrice: (json['packagePrice'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 1,
      estimatedDuration: Duration(minutes: json['estimatedDurationMinutes'] ?? 30),
      requirements: List<String>.from(json['requirements'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'description': description,
      'originalPrice': originalPrice,
      'packagePrice': packagePrice,
      'quantity': quantity,
      'estimatedDurationMinutes': estimatedDuration.inMinutes,
      'requirements': requirements,
    };
  }
}

enum PackageType {
  standard,
  premium,
  bulk,
  seasonal,
  maintenance,
  emergency,
}

extension PackageTypeExtension on PackageType {
  String get displayName {
    switch (this) {
      case PackageType.standard:
        return 'Standard Package';
      case PackageType.premium:
        return 'Premium Package';
      case PackageType.bulk:
        return 'Bulk Package';
      case PackageType.seasonal:
        return 'Seasonal Package';
      case PackageType.maintenance:
        return 'Maintenance Package';
      case PackageType.emergency:
        return 'Emergency Package';
    }
  }

  String get description {
    switch (this) {
      case PackageType.standard:
        return 'Regular service package with standard features';
      case PackageType.premium:
        return 'Enhanced service package with premium features';
      case PackageType.bulk:
        return 'Volume-based package for multiple services';
      case PackageType.seasonal:
        return 'Time-limited seasonal offers';
      case PackageType.maintenance:
        return 'Ongoing maintenance and support services';
      case PackageType.emergency:
        return 'Priority emergency response services';
    }
  }
}
