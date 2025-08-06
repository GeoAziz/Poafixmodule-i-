import 'chat_message.dart';

class ChatModel {
  final String id;
  final String bookingId;
  final String clientId;
  final String clientName;
  final String providerId;
  final String providerName;
  final String serviceType;
  final ChatMessage? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isActive;
  final ChatStatus status;

  ChatModel({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.clientName,
    required this.providerId,
    required this.providerName,
    required this.serviceType,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.isActive = true,
    this.status = ChatStatus.active,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['_id'] ?? json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'] ?? '',
      providerId: json['providerId'] ?? '',
      providerName: json['providerName'] ?? '',
      serviceType: json['serviceType'] ?? '',
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      unreadCount: json['unreadCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      status: ChatStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ChatStatus.active,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'clientId': clientId,
      'clientName': clientName,
      'providerId': providerId,
      'providerName': providerName,
      'serviceType': serviceType,
      'lastMessage': lastMessage?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'status': status.toString().split('.').last,
    };
  }
}

enum ChatStatus {
  active,
  archived,
  blocked,
  completed
}