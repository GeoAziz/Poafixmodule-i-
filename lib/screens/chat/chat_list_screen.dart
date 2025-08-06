import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/chat_room.dart';
import '../../models/chat_message.dart'; // import added
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../services/websocket_service.dart';
import 'chat_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListScreen extends StatefulWidget {
  final User user;

  const ChatListScreen({super.key, required this.user}); // use super parameter

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final WebSocketService _webSocketService = WebSocketService();
  final _storage = FlutterSecureStorage();

  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
    _setupWebSocketListener();
  }

  void _setupWebSocketListener() {
    _webSocketService.socket.on('new_message', (data) {
      if (mounted) {
        _loadChatRooms(); // Refresh chat list when new message arrives
      }
    });

    _webSocketService.socket.on('room_updated', (data) {
      if (mounted) {
        _loadChatRooms(); // Refresh when room is updated
      }
    });
  }

  Future<void> _loadChatRooms() async {
    try {
      final userId = widget.user.id ?? await _storage.read(key: 'user_id');
      if (userId == null) throw Exception('User ID not found');

      final rooms = await _chatService.getChatRooms(userId);

      if (mounted) {
        setState(() {
          _chatRooms = rooms;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadChatRooms,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Error loading chats'),
            Text(_error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChatRooms,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_chatRooms.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadChatRooms,
      child: ListView.builder(
        itemCount: _chatRooms.length,
        itemBuilder: (context, index) {
          final room = _chatRooms[index];
          return _buildChatRoomTile(room);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start chatting with your service providers',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomTile(ChatRoom room) {
    final currentUserId = widget.user.id;
    final otherUserName = room.getOtherUserName(currentUserId);
    final otherUserAvatar = room.getOtherUserAvatar(currentUserId);
    final lastMessage = room.lastMessage;
    final hasUnread = room.unreadCount > 0;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          backgroundImage:
              otherUserAvatar != null ? NetworkImage(otherUserAvatar) : null,
          child: otherUserAvatar == null
              ? Icon(Icons.person, color: Colors.blue[600])
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherUserName,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (hasUnread)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  room.unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: lastMessage != null
            ? Text(
                _getLastMessagePreview(lastMessage),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasUnread ? Colors.black87 : Colors.grey[600],
                  fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                ),
              )
            : Text('Tap to start conversation'),
        trailing: lastMessage != null
            ? Text(
                timeago.format(lastMessage.timestamp),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              )
            : null,
        onTap: () => _openChat(room),
      ),
    );
  }

  String _getLastMessagePreview(ChatMessage message) {
    switch (message.type) {
      case 'image':
        return '📷 Photo';
      case 'location':
        return '📍 Location';
      case 'system':
        return message.content;
      default:
        return message.content;
    }
  }

  void _openChat(ChatRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoom: room,
          currentUser: widget.user,
        ),
      ),
    ).then((_) {
      // Refresh chat list when returning from chat
      _loadChatRooms();
    });
  }

  @override
  void dispose() {
    _webSocketService.socket.off('new_message');
    _webSocketService.socket.off('room_updated');
    super.dispose();
  }
}
