class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? bookingId;
  final Map<String, dynamic> data;
  bool read;
  final String recipientId;
  final String recipientType;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.bookingId,
    required this.data,
    required this.recipientId,
    required this.recipientType,
    this.read = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      bookingId: json['bookingId'] ?? json['data']?['bookingId'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      data: json['data'] ?? {},
      recipientId: json['recipientId'] ?? '',
      recipientType: json['recipientType'] ?? '',
      read: json['read'] ?? json['isRead'] ?? false,
    );
  }
}
