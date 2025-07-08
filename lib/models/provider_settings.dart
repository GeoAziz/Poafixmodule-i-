class ProviderSettings {
  final String providerId;
  final Map<String, WorkingHours> workingHours;
  final NotificationSettings notifications;
  final LocationSettings locationTracking;
  final PaymentPreferences paymentPreferences;
  final ServiceArea serviceArea;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProviderSettings({
    required this.providerId,
    required this.workingHours,
    required this.notifications,
    required this.locationTracking,
    required this.paymentPreferences,
    required this.serviceArea,
    this.createdAt,
    this.updatedAt,
  });

  factory ProviderSettings.fromJson(Map<String, dynamic> json) {
    return ProviderSettings(
      providerId: json['providerId'],
      workingHours: (json['workingHours'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, WorkingHours.fromJson(value)),
      ),
      notifications: NotificationSettings.fromJson(json['notifications']),
      locationTracking: LocationSettings.fromJson(json['locationTracking']),
      paymentPreferences:
          PaymentPreferences.fromJson(json['paymentPreferences']),
      serviceArea: ServiceArea.fromJson(json['serviceArea']),
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'workingHours':
            workingHours.map((key, value) => MapEntry(key, value.toJson())),
        'notifications': notifications.toJson(),
        'locationTracking': locationTracking.toJson(),
        'paymentPreferences': paymentPreferences.toJson(),
        'serviceArea': serviceArea.toJson(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class WorkingHours {
  final String start;
  final String end;
  final bool isActive;

  WorkingHours({
    required this.start,
    required this.end,
    required this.isActive,
  });

  factory WorkingHours.fromJson(Map<String, dynamic> json) => WorkingHours(
        start: json['start'],
        end: json['end'],
        isActive: json['isActive'],
      );

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'isActive': isActive,
      };
}

class NotificationSettings {
  final bool bookingRequests;
  final bool messages;
  final bool updates;
  final bool marketing;
  final bool pushEnabled;
  final bool emailEnabled;

  NotificationSettings({
    required this.bookingRequests,
    required this.messages,
    required this.updates,
    required this.marketing,
    this.pushEnabled = false, // Add default values
    this.emailEnabled = false, // Add default values
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      bookingRequests: json['bookingRequests'] ?? false,
      messages: json['messages'] ?? false,
      updates: json['updates'] ?? false,
      marketing: json['marketing'] ?? false,
      pushEnabled: json['pushEnabled'] ?? false,
      emailEnabled: json['emailEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'bookingRequests': bookingRequests,
        'messages': messages,
        'updates': updates,
        'marketing': marketing,
        'pushEnabled': pushEnabled,
        'emailEnabled': emailEnabled,
      };
}

class LocationSettings {
  final bool enabled;
  final String accuracy;

  LocationSettings({
    required this.enabled,
    required this.accuracy,
  });

  factory LocationSettings.fromJson(Map<String, dynamic> json) =>
      LocationSettings(
        enabled: json['enabled'],
        accuracy: json['accuracy'],
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'accuracy': accuracy,
      };
}

class PaymentPreferences {
  final bool mpesa;
  final bool cash;
  final bool autoWithdrawal;
  final double minimumWithdrawal;

  PaymentPreferences({
    required this.mpesa,
    required this.cash,
    required this.autoWithdrawal,
    required this.minimumWithdrawal,
  });

  factory PaymentPreferences.fromJson(Map<String, dynamic> json) =>
      PaymentPreferences(
        mpesa: json['mpesa'],
        cash: json['cash'],
        autoWithdrawal: json['autoWithdrawal'],
        minimumWithdrawal: json['minimumWithdrawal'].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'mpesa': mpesa,
        'cash': cash,
        'autoWithdrawal': autoWithdrawal,
        'minimumWithdrawal': minimumWithdrawal,
      };
}

class ServiceArea {
  final double radius;
  final GeoLocation baseLocation;

  ServiceArea({
    required this.radius,
    required this.baseLocation,
  });

  factory ServiceArea.fromJson(Map<String, dynamic> json) => ServiceArea(
        radius: json['radius'].toDouble(),
        baseLocation: GeoLocation.fromJson(json['baseLocation']),
      );

  Map<String, dynamic> toJson() => {
        'radius': radius,
        'baseLocation': baseLocation.toJson(),
      };
}

class GeoLocation {
  final String type;
  final List<double> coordinates;

  GeoLocation({
    this.type = 'Point',
    required this.coordinates,
  });

  factory GeoLocation.fromJson(Map<String, dynamic> json) => GeoLocation(
        type: json['type'],
        coordinates: List<double>.from(json['coordinates']),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'coordinates': coordinates,
      };
}
