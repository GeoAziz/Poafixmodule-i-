import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
import '../../models/chat_room.dart';
import '../../models/chat_message.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../services/websocket_service.dart';
import '../../services/call_service.dart';
import '../../widgets/chat_message_bubble.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final User currentUser;

  const ChatScreen({
    super.key,
    required this.chatRoom,
    required this.currentUser,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final WebSocketService _webSocketService = WebSocketService();
  final CallService _callService = CallService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreMessages = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupWebSocketListener();
    _markMessagesAsRead();
    _scrollController.addListener(_onScroll);
  }

  void _setupWebSocketListener() {
    _webSocketService.socket.on('new_message', (data) {
      final message = ChatMessage.fromJson(data);
      if (message.roomId == widget.chatRoom.id && mounted) {
        setState(() {
          _messages.insert(0, message);
        });
        _scrollToBottom();
        _markMessagesAsRead();
      }
    });

    _webSocketService.socket.on('message_deleted', (data) {
      final messageId = data['messageId'];
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == messageId);
        });
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMoreMessages &&
        !_isLoading) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.getMessages(
        roomId: widget.chatRoom.id,
        page: 1,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _messages = messages.reversed.toList();
          _isLoading = false;
          _error = null;
          _hasMoreMessages = messages.length == 50;
        });
        _scrollToBottom();
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

  Future<void> _loadMoreMessages() async {
    if (_isLoading || !_hasMoreMessages) return;

    setState(() => _isLoading = true);

    try {
      final messages = await _chatService.getMessages(
        roomId: widget.chatRoom.id,
        page: _currentPage + 1,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _messages.addAll(messages.reversed.toList());
          _currentPage++;
          _isLoading = false;
          _hasMoreMessages = messages.length == 50;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(
      roomId: widget.chatRoom.id,
      userId: widget.currentUser.id,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final otherUserName =
        widget.chatRoom.getOtherUserName(widget.currentUser.id);
    final otherUserAvatar =
        widget.chatRoom.getOtherUserAvatar(widget.currentUser.id);
    final otherUserId = widget.chatRoom.getOtherUserId(widget.currentUser.id);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              backgroundImage: otherUserAvatar != null
                  ? NetworkImage(otherUserAvatar)
                  : null,
              child: otherUserAvatar == null
                  ? Icon(Icons.person, color: Colors.blue[600], size: 20)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                otherUserName,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.call),
            onPressed: () => _makeVoiceCall(otherUserId, otherUserName),
          ),
          IconButton(
            icon: Icon(Icons.videocam),
            onPressed: () => _makeVideoCall(otherUserId, otherUserName),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _showClearChatDialog();
                  break;
                case 'block':
                  _showBlockUserDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Chat'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Block User', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading && _messages.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Error loading messages'),
            Text(_error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            Text(
              'Start the conversation!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      itemCount: _messages.length + (_hasMoreMessages ? 1 : 0),
      itemBuilder: (context, index) {
        if (_hasMoreMessages && index == _messages.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final message = _messages[index];
        final isMe = message.senderId == widget.currentUser.id;
        final showTimestamp = _shouldShowTimestamp(index);

        return Column(
          children: [
            if (showTimestamp) _buildTimestamp(message.timestamp),
            GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: ChatMessageBubble(
                message: message,
                isMe: isMe,
              ),
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowTimestamp(int index) {
    if (index == _messages.length - 1) return true;

    final current = _messages[index];
    final next = _messages[index + 1];

    return current.timestamp.difference(next.timestamp).inMinutes > 30;
  }

  Widget _buildTimestamp(DateTime timestamp) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        timeago.format(timestamp),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.blue[600]),
            onPressed: _showAttachmentOptions,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendTextMessage(),
              maxLines: null,
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue[600],
            child: IconButton(
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : _sendTextMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: 'Location',
                  onTap: _shareLocation,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[100],
            child: Icon(icon, color: Colors.blue[600], size: 30),
          ),
          SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _chatService.sendMessage(
        roomId: widget.chatRoom.id,
        senderId: widget.currentUser.id,
        content: text,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
      _messageController.text = text; // Restore message on error
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _chatService.sendImageMessage(
          roomId: widget.chatRoom.id,
          senderId: widget.currentUser.id,
          imageFile: File(image.path),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: $e')),
      );
    }
  }

  Future<void> _shareLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();

      await _chatService.sendLocationMessage(
        roomId: widget.chatRoom.id,
        senderId: widget.currentUser.id,
        latitude: position.latitude,
        longitude: position.longitude,
        address: 'Current Location',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share location: $e')),
      );
    }
  }

  void _showMessageOptions(ChatMessage message) {
    final isMe = message.senderId == widget.currentUser.id;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.copy),
              title: Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Message copied')),
                );
              },
            ),
            if (isMe) ...[
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    try {
      await _chatService.deleteMessage(message.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete message')),
      );
    }
  }

  void _makeVoiceCall(String userId, String userName) {
    _callService.initiateCall(
      calleeId: userId,
      calleeName: userName,
      isVideoCall: false,
    );
  }

  void _makeVideoCall(String userId, String userName) {
    _callService.initiateCall(
      calleeId: userId,
      calleeName: userName,
      isVideoCall: true,
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Chat'),
        content: Text(
            'Are you sure you want to clear this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement clear chat functionality
            },
            child: Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog() {
    final otherUserName =
        widget.chatRoom.getOtherUserName(widget.currentUser.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block User'),
        content: Text('Are you sure you want to block $otherUserName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement block user functionality
            },
            child: Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _webSocketService.socket.off('new_message');
    _webSocketService.socket.off('message_deleted');
    super.dispose();
  }
}
