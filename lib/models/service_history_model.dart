class ServiceHistoryModel {
  final String id;
  final String userId;
  final String userType; // 'client' or 'provider'
  final String serviceId;
  final String serviceName;
  final String serviceType;
  final String providerId;
  final String providerName;
  final String clientId;
  final String clientName;
  final DateTime serviceDate;
  final DateTime completedDate;
  final double amount;
  final String status; // 'completed', 'cancelled', 'refunded'
  final double? rating;
  final String? review;
  final Map<String, dynamic> serviceDetails;
  final List<String> attachments;
  final Duration serviceDuration;
  final Map<String, dynamic> location;
  final String paymentMethod;
  final String paymentStatus;
  final List<ServiceHistoryAction> actions;
  final Map<String, dynamic> metadata;

  ServiceHistoryModel({
    required this.id,
    required this.userId,
    required this.userType,
    required this.serviceId,
    required this.serviceName,
    required this.serviceType,
    required this.providerId,
    required this.providerName,
    required this.clientId,
    required this.clientName,
    required this.serviceDate,
    required this.completedDate,
    required this.amount,
    required this.status,
    this.rating,
    this.review,
    required this.serviceDetails,
    this.attachments = const [],
    required this.serviceDuration,
    required this.location,
    required this.paymentMethod,
    required this.paymentStatus,
    this.actions = const [],
    this.metadata = const {},
  });

  factory ServiceHistoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceHistoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      userType: json['userType'] ?? 'client',
      serviceId: json['serviceId'] ?? '',
      serviceName: json['serviceName'] ?? '',
      serviceType: json['serviceType'] ?? '',
      providerId: json['providerId'] ?? '',
      providerName: json['providerName'] ?? '',
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'] ?? '',
      serviceDate: DateTime.parse(json['serviceDate'] ?? DateTime.now().toIso8601String()),
      completedDate: DateTime.parse(json['completedDate'] ?? DateTime.now().toIso8601String()),
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'completed',
      rating: json['rating']?.toDouble(),
      review: json['review'],
      serviceDetails: Map<String, dynamic>.from(json['serviceDetails'] ?? {}),
      attachments: List<String>.from(json['attachments'] ?? []),
      serviceDuration: Duration(minutes: json['serviceDurationMinutes'] ?? 0),
      location: Map<String, dynamic>.from(json['location'] ?? {}),
      paymentMethod: json['paymentMethod'] ?? '',
      paymentStatus: json['paymentStatus'] ?? '',
      actions: (json['actions'] as List?)
          ?.map((action) => ServiceHistoryAction.fromJson(action))
          .toList() ?? [],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userType': userType,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceType': serviceType,
      'providerId': providerId,
      'providerName': providerName,
      'clientId': clientId,
      'clientName': clientName,
      'serviceDate': serviceDate.toIso8601String(),
      'completedDate': completedDate.toIso8601String(),
      'amount': amount,
      'status': status,
      'rating': rating,
      'review': review,
      'serviceDetails': serviceDetails,
      'attachments': attachments,
      'serviceDurationMinutes': serviceDuration.inMinutes,
      'location': location,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'actions': actions.map((action) => action.toJson()).toList(),
      'metadata': metadata,
    };
  }

  // Helper methods
  bool get canRebook => status == 'completed' && DateTime.now().difference(completedDate).inDays > 1;
  bool get canRate => status == 'completed' && rating == null;
  bool get canReview => status == 'completed' && review == null;
  String get formattedAmount => 'KES ${amount.toStringAsFixed(2)}';
  String get formattedDuration => '${serviceDuration.inHours}h ${serviceDuration.inMinutes % 60}m';
}

class ServiceHistoryAction {
  final String id;
  final String type; // 'rebook', 'rate', 'review', 'refund', 'contact'
  final String title;
  final String description;
  final bool isEnabled;
  final Map<String, dynamic>? data;

  ServiceHistoryAction({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.isEnabled = true,
    this.data,
  });

  factory ServiceHistoryAction.fromJson(Map<String, dynamic> json) {
    return ServiceHistoryAction(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isEnabled: json['isEnabled'] ?? true,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'isEnabled': isEnabled,
      'data': data,
    };
  }
}