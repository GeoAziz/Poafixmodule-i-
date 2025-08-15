class NotificationModel {
  final String id;
  final String recipientId;
  final String recipientModel; // Added recipientModel property
  final String type;
  final String title;
  final String message;
  final bool? read; // or int? status;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.recipientModel, // Initialize recipientModel
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    print('🔄 Creating NotificationModel from JSON:');
    print(json);

    // Extract the actual document data from nested structure
    final doc = json['_doc'] ?? json;

    final model = NotificationModel(
      id: doc['_id'] ?? '',
      recipientId: doc['recipientId'] ?? '',
      recipientModel: doc['recipientModel'] ?? 'Unknown', // Map recipientModel
      type: doc['type'] ?? 'SYSTEM_ALERT',
      title: doc['title'] ?? '',
      message: doc['message'] ?? '',
      read: doc['read'] ?? false,
      createdAt:
          DateTime.parse(doc['createdAt'] ?? DateTime.now().toIso8601String()),
      data: doc['data'],
    );

    print('✅ Created NotificationModel:');
    print('Title: ${model.title}');
    print('Message: ${model.message}');
    print('Data: ${model.data}');
    return model;
  }

  bool get isRead => read == true; // or: status == 1;

  @override
  String toString() {
    return 'NotificationModel{id: $id, title: $title, message: $message}';
  }
}
