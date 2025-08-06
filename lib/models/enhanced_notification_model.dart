class EnhancedNotificationModel {
  final String id;
  final String recipientId;
  final String recipientType;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final NotificationPriority priority;
  final List<NotificationAction> actions;
  final String? imageUrl;
  final String? deepLink;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final bool isRead;
  final bool isDelivered;
  final bool isCancellable;
  final String? category;
  final Map<String, String>? customData;

  EnhancedNotificationModel({
    required this.id,
    required this.recipientId,
    required this.recipientType,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.priority = NotificationPriority.normal,
    this.actions = const [],
    this.imageUrl,
    this.deepLink,
    required this.createdAt,
    this.scheduledFor,
    this.isRead = false,
    this.isDelivered = false,
    this.isCancellable = true,
    this.category,
    this.customData,
  });

  factory EnhancedNotificationModel.fromJson(Map<String, dynamic> json) {
    return EnhancedNotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      recipientId: json['recipientId'] ?? '',
      recipientType: json['recipientType'] ?? 'client',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.general,
      ),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'],
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      actions: json['actions'] != null
          ? (json['actions'] as List)
              .map((action) => NotificationAction.fromJson(action))
              .toList()
          : [],
      imageUrl: json['imageUrl'],
      deepLink: json['deepLink'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.parse(json['scheduledFor'])
          : null,
      isRead: json['isRead'] ?? false,
      isDelivered: json['isDelivered'] ?? false,
      isCancellable: json['isCancellable'] ?? true,
      category: json['category'],
      customData: json['customData'] != null
          ? Map<String, String>.from(json['customData'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientId': recipientId,
      'recipientType': recipientType,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'data': data,
      'priority': priority.toString().split('.').last,
      'actions': actions.map((action) => action.toJson()).toList(),
      'imageUrl': imageUrl,
      'deepLink': deepLink,
      'createdAt': createdAt.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'isRead': isRead,
      'isDelivered': isDelivered,
      'isCancellable': isCancellable,
      'category': category,
      'customData': customData,
    };
  }
}

enum NotificationType {
  // Booking related
  bookingRequest,
  bookingAccepted,
  bookingRejected,
  bookingCancelled,
  bookingModified,
  bookingReminder,
  
  // Service related
  serviceStarted,
  serviceCompleted,
  serviceOnTheWay,
  serviceDelayed,
  serviceRescheduled,
  
  // Payment related
  paymentDue,
  paymentReceived,
  paymentFailed,
  paymentRefunded,
  paymentOverdue,
  
  // Communication
  newMessage,
  missedCall,
  callRequest,
  
  // Account related
  accountVerified,
  accountBlocked,
  accountUnblocked,
  profileUpdated,
  passwordChanged,
  
  // Rating & Reviews
  ratingRequest,
  newReview,
  ratingReceived,
  
  // System notifications
  systemMaintenance,
  systemUpdate,
  appUpdate,
  emergency,
  
  // Marketing & Promotions
  promotion,
  newsletter,
  announcement,
  
  // Location & Tracking
  providerNearby,
  locationUpdate,
  geofenceEnter,
  geofenceExit,
  
  // General
  general,
  reminder,
  alert,
  info,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
  critical,
}

class NotificationAction {
  final String id;
  final String title;
  final String action;
  final Map<String, dynamic>? data;
  final bool isDestructive;

  NotificationAction({
    required this.id,
    required this.title,
    required this.action,
    this.data,
    this.isDestructive = false,
  });

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      action: json['action'] ?? '',
      data: json['data'],
      isDestructive: json['isDestructive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'action': action,
      'data': data,
      'isDestructive': isDestructive,
    };
  }
}