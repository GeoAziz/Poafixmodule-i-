class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String senderType; // 'client' or 'provider'
  final String receiverId;
  final String receiverName;
  final String content;
  final MessageType type;
  final List<String> attachments;
  final DateTime timestamp;
  final bool isRead;
  final bool isDelivered;
  final String? replyToMessageId;
  final MessageStatus status;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.receiverId,
    required this.receiverName,
    required this.content,
    required this.type,
    this.attachments = const [],
    required this.timestamp,
    this.isRead = false,
    this.isDelivered = false,
    this.replyToMessageId,
    this.status = MessageStatus.sent,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderType: json['senderType'] ?? 'client',
      receiverId: json['receiverId'] ?? '',
      receiverName: json['receiverName'] ?? '',
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MessageType.text,
      ),
      attachments: List<String>.from(json['attachments'] ?? []),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      isDelivered: json['isDelivered'] ?? false,
      replyToMessageId: json['replyToMessageId'],
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'content': content,
      'type': type.toString().split('.').last,
      'attachments': attachments,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isDelivered': isDelivered,
      'replyToMessageId': replyToMessageId,
      'status': status.toString().split('.').last,
    };
  }
}

enum MessageType {
  text,
  image,
  file,
  audio,
  video,
  location,
  system,
  call_invite,
  payment_request
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed
}