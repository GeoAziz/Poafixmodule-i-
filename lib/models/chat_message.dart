import 'dart:convert';

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String senderType; // 'client' or 'provider'
  final String content;
  final String type; // 'text', 'image', 'location', 'system'
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final String? thumbnailUrl;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.content,
    required this.type,
    this.metadata,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.thumbnailUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['id'],
      roomId: json['roomId'],
      senderId: json['senderId'],
      senderName: json['senderName'] ?? 'Unknown',
      senderType: json['senderType'] ?? 'client',
      content: json['content'],
      type: json['type'] ?? 'text',
      metadata: json['metadata'],
      timestamp: DateTime.parse(json['timestamp'] ?? json['createdAt']),
      isRead: json['isRead'] ?? false,
      imageUrl: json['imageUrl'],
      thumbnailUrl: json['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'content': content,
      'type': type,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  bool get isImage => type == 'image';
  bool get isLocation => type == 'location';
  bool get isSystem => type == 'system';

  Map<String, dynamic>? get locationData {
    if (isLocation && content.isNotEmpty) {
      try {
        return Map<String, dynamic>.from(
          json.decode(content) as Map<String, dynamic>
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}