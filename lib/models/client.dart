class Client {
  final String id;
  final String name;
  final String email;
  final bool isBlocked;
  final bool isOnline;

  Client({
    required this.id,
    required this.name,
    required this.email,
    this.isBlocked = false,
    this.isOnline = false,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      isBlocked: json['isBlocked'] ?? false,
      isOnline: json['isOnline'] ?? false,
    );
  }
}

class ServicePreference {
  final String service;

  ServicePreference({required this.service});

  factory ServicePreference.fromJson(Map<String, dynamic> json) {
    return ServicePreference(service: json['service']);
  }
}

class ActivityHistory {
  final String serviceName;
  final String provider;
  final String status;

  ActivityHistory({
    required this.serviceName,
    required this.provider,
    required this.status,
  });

  factory ActivityHistory.fromJson(Map<String, dynamic> json) {
    return ActivityHistory(
      serviceName: json['serviceName'],
      provider: json['provider'],
      status: json['status'],
    );
  }
}

class RatingReview {
  final String review;
  final int rating;

  RatingReview({required this.review, required this.rating});

  factory RatingReview.fromJson(Map<String, dynamic> json) {
    return RatingReview(review: json['review'], rating: json['rating']);
  }
}

class PaymentDetails {
  final String creditCard;
  final String billingHistory;

  PaymentDetails({required this.creditCard, required this.billingHistory});

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      creditCard: json['creditCard'],
      billingHistory: json['billingHistory'],
    );
  }
}

class Settings {
  final String notificationPreferences;
  final String privacySettings;
  final String languageSettings;

  Settings({
    required this.notificationPreferences,
    required this.privacySettings,
    required this.languageSettings,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      notificationPreferences: json['notificationPreferences'],
      privacySettings: json['privacySettings'],
      languageSettings: json['languageSettings'],
    );
  }
}
