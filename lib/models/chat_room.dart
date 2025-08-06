import 'chat_message.dart';

class ChatRoom {
  final String id;
  final String name;
  final List<String> participants;
  final ChatMessage? lastMessage; // changed from String? to ChatMessage?
  final DateTime? lastMessageTime;
  final bool isGroup;
  final String? adminId;
  final Map<String, dynamic>? metadata;

  ChatRoom({
    required this.id,
    required this.name,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.isGroup = false,
    this.adminId,
    this.metadata,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : null,
      isGroup: json['isGroup'] ?? false,
      adminId: json['adminId'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'participants': participants,
      'lastMessage': lastMessage?.toJson(),
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'isGroup': isGroup,
      'adminId': adminId,
      'metadata': metadata,
    };
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    List<String>? participants,
    ChatMessage? lastMessage,
    DateTime? lastMessageTime,
    bool? isGroup,
    String? adminId,
    Map<String, dynamic>? metadata,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isGroup: isGroup ?? this.isGroup,
      adminId: adminId ?? this.adminId,
      metadata: metadata ?? this.metadata,
    );
  }

  // Returns the other user's name (for 1:1 chat)
  String getOtherUserName(String currentUserId) {
    if (isGroup) return name;
    final otherId =
        participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    if (metadata != null && metadata!['users'] != null) {
      final users = metadata!['users'] as List<dynamic>;
      final user =
          users.firstWhere((u) => u['id'] == otherId, orElse: () => null);
      if (user != null && user['name'] != null) return user['name'];
    }
    return 'Unknown';
  }

  // Returns the other user's avatar URL (for 1:1 chat)
  String? getOtherUserAvatar(String currentUserId) {
    if (isGroup) return null;
    final otherId =
        participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    if (metadata != null && metadata!['users'] != null) {
      final users = metadata!['users'] as List<dynamic>;
      final user =
          users.firstWhere((u) => u['id'] == otherId, orElse: () => null);
      if (user != null && user['avatar'] != null) return user['avatar'];
    }
    return null;
  }

  // Returns unread message count if available in metadata
  int get unreadCount {
    if (metadata != null && metadata!['unreadCount'] != null) {
      return metadata!['unreadCount'] as int;
    }
    return 0;
  }
  // Returns the other user's id (for 1:1 chat)
  String getOtherUserId(String currentUserId) {
    if (isGroup) return '';
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }
}
  // Returns the other user's id (for 1:1 chat)
  String getOtherUserId(String currentUserId) {
    if (isGroup) return '';
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }
