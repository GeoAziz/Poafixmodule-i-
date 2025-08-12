import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../models/chat_message.dart';
import 'websocket_service.dart';
import 'api_config.dart';

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  final _storage = const FlutterSecureStorage();
  final _webSocketService = WebSocketService();

  // Stream controllers
  final _messageStreamController = StreamController<MessageModel>.broadcast();
  final _chatListStreamController =
      StreamController<List<ChatModel>>.broadcast();
  final _typingStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onlineStatusStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Streams
  Stream<MessageModel> get messageStream => _messageStreamController.stream;
  Stream<List<ChatModel>> get chatListStream =>
      _chatListStreamController.stream;
  Stream<Map<String, dynamic>> get typingStream =>
      _typingStreamController.stream;
  Stream<Map<String, dynamic>> get onlineStatusStream =>
      _onlineStatusStreamController.stream;

  // Local cache
  final Map<String, List<MessageModel>> _messageCache = {};
  final Map<String, ChatModel> _chatCache = {};

  Future<void> initialize() async {
    _setupWebSocketListeners();
  }

  void _setupWebSocketListeners() {
    // Listen for new messages
    _webSocketService.socket.on('new_message', (data) {
      final message = MessageModel.fromJson(data);
      _messageStreamController.add(message);
      _updateChatCache(message);
    });

    // Listen for message status updates
    _webSocketService.socket.on('message_status_update', (data) {
      _handleMessageStatusUpdate(data);
    });

    // Listen for typing indicators
    _webSocketService.socket.on('user_typing', (data) {
      _typingStreamController.add(data);
    });

    // Listen for online status
    _webSocketService.socket.on('user_online_status', (data) {
      _onlineStatusStreamController.add(data);
    });

    // Listen for chat updates
    _webSocketService.socket.on('chat_updated', (data) {
      final chat = ChatModel.fromJson(data);
      _chatCache[chat.id] = chat;
      _refreshChatList();
    });
  }

  // Chat Management
  Future<List<ChatModel>> getChats() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final chats = (data['data'] as List)
            .map((chat) => ChatModel.fromJson(chat))
            .toList();

        // Update cache
        for (final chat in chats) {
          _chatCache[chat.id] = chat;
        }

        _chatListStreamController.add(chats);
        return chats;
      }
      throw Exception('Failed to load chats');
    } catch (e) {
      throw Exception('Error loading chats: $e');
    }
  }

  Future<ChatModel> createOrGetChat({
    required String bookingId,
    required String clientId,
    required String clientName,
    required String providerId,
    required String providerName,
    required String serviceType,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'bookingId': bookingId,
          'clientId': clientId,
          'clientName': clientName,
          'providerId': providerId,
          'providerName': providerName,
          'serviceType': serviceType,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final chat = ChatModel.fromJson(data['data']);
        _chatCache[chat.id] = chat;
        return chat;
      }
      throw Exception('Failed to create chat');
    } catch (e) {
      throw Exception('Error creating chat: $e');
    }
  }

  // Message Management
  Future<List<MessageModel>> getMessages(String chatId,
      {int page = 1, int limit = 50}) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/chats/$chatId/messages?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final messages = (data['data'] as List)
            .map((message) => MessageModel.fromJson(message))
            .toList();

        // Update cache
        if (_messageCache[chatId] == null) {
          _messageCache[chatId] = [];
        }

        if (page == 1) {
          _messageCache[chatId] = messages;
        } else {
          _messageCache[chatId]!.addAll(messages);
        }

        return messages;
      }
      throw Exception('Failed to load messages');
    } catch (e) {
      throw Exception('Error loading messages: $e');
    }
  }

  Future<MessageModel> sendMessage({
    required String chatId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    List<String> attachments = const [],
    String? replyToMessageId,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final userId = await _storage.read(key: 'user_id');
      final userName = await _storage.read(key: 'user_name') ?? 'User';
      final userType = await _storage.read(key: 'userType') ?? 'client';

      final messageData = {
        'chatId': chatId,
        'senderId': userId,
        'senderName': userName,
        'senderType': userType,
        'receiverId': receiverId,
        'content': content,
        'type': type.toString().split('.').last,
        'attachments': attachments,
        'replyToMessageId': replyToMessageId,
      };

      // Send via WebSocket for real-time delivery
      _webSocketService.emit('send_message', messageData);

      // Also send via HTTP for persistence
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/chats/$chatId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(messageData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final message = MessageModel.fromJson(data['data']);

        // Update local cache
        if (_messageCache[chatId] != null) {
          _messageCache[chatId]!.insert(0, message);
        }

        return message;
      }
      throw Exception('Failed to send message');
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  Future<String> uploadFile(File file, {required String chatId}) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/chats/$chatId/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return data['fileUrl'];
      }
      throw Exception('Failed to upload file');
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  Future<MessageModel> sendImageMessage({
    required String chatId,
    required String receiverId,
    required File imageFile,
    String? caption,
  }) async {
    try {
      // Upload image first
      final imageUrl = await uploadFile(imageFile, chatId: chatId);

      // Send message with image
      return await sendMessage(
        chatId: chatId,
        receiverId: receiverId,
        content: caption ?? '',
        type: MessageType.image,
        attachments: [imageUrl],
      );
    } catch (e) {
      throw Exception('Error sending image: $e');
    }
  }

  Future<MessageModel> sendFileMessage({
    required String chatId,
    required String receiverId,
    required File file,
    String? description,
  }) async {
    try {
      // Upload file first
      final fileUrl = await uploadFile(file, chatId: chatId);

      // Send message with file
      return await sendMessage(
        chatId: chatId,
        receiverId: receiverId,
        content: description ?? file.path.split('/').last,
        type: MessageType.file,
        attachments: [fileUrl],
      );
    } catch (e) {
      throw Exception('Error sending file: $e');
    }
  }

  // Message Status Management
  Future<void> markAsRead(String chatId, String messageId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      await http.patch(
        Uri.parse(
            '${ApiConfig.baseUrl}/chats/$chatId/messages/$messageId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Emit via WebSocket
      _webSocketService.emit('mark_as_read', {
        'chatId': chatId,
        'messageId': messageId,
      });
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  Future<void> markChatAsRead(String chatId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/chats/$chatId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Update local cache
      if (_chatCache[chatId] != null) {
        final updatedChat = ChatModel(
          id: _chatCache[chatId]!.id,
          bookingId: _chatCache[chatId]!.bookingId,
          clientId: _chatCache[chatId]!.clientId,
          clientName: _chatCache[chatId]!.clientName,
          providerId: _chatCache[chatId]!.providerId,
          providerName: _chatCache[chatId]!.providerName,
          serviceType: _chatCache[chatId]!.serviceType,
          lastMessage: _chatCache[chatId]!.lastMessage,
          createdAt: _chatCache[chatId]!.createdAt,
          updatedAt: _chatCache[chatId]!.updatedAt,
          unreadCount: 0, // Reset unread count
          isActive: _chatCache[chatId]!.isActive,
          status: _chatCache[chatId]!.status,
        );
        _chatCache[chatId] = updatedChat;
        _refreshChatList();
      }
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  // Typing Indicators
  void startTyping(String chatId, String receiverId) {
    _webSocketService.emit('start_typing', {
      'chatId': chatId,
      'receiverId': receiverId,
    });
  }

  void stopTyping(String chatId, String receiverId) {
    _webSocketService.emit('stop_typing', {
      'chatId': chatId,
      'receiverId': receiverId,
    });
  }

  // Helper methods
  void _handleMessageStatusUpdate(Map<String, dynamic> data) {
    final chatId = data['chatId'];
    final messageId = data['messageId'];
    final status = data['status'];

    if (_messageCache[chatId] != null) {
      final messageIndex =
          _messageCache[chatId]!.indexWhere((msg) => msg.id == messageId);

      if (messageIndex != -1) {
        final oldMessage = _messageCache[chatId]![messageIndex];
        final updatedMessage = MessageModel(
          id: oldMessage.id,
          chatId: oldMessage.chatId,
          senderId: oldMessage.senderId,
          senderName: oldMessage.senderName,
          senderType: oldMessage.senderType,
          receiverId: oldMessage.receiverId,
          receiverName: oldMessage.receiverName,
          content: oldMessage.content,
          type: oldMessage.type,
          attachments: oldMessage.attachments,
          timestamp: oldMessage.timestamp,
          isRead: status == 'read' ? true : oldMessage.isRead,
          isDelivered: status == 'delivered' ? true : oldMessage.isDelivered,
          replyToMessageId: oldMessage.replyToMessageId,
          status: MessageStatus.values.firstWhere(
            (e) => e.toString().split('.').last == status,
            orElse: () => oldMessage.status,
          ),
        );

        _messageCache[chatId]![messageIndex] = updatedMessage;
      }
    }
  }

  void _updateChatCache(MessageModel message) {
    if (_chatCache[message.chatId] != null) {
      final chat = _chatCache[message.chatId]!;
      final updatedChat = ChatModel(
        id: chat.id,
        bookingId: chat.bookingId,
        clientId: chat.clientId,
        clientName: chat.clientName,
        providerId: chat.providerId,
        providerName: chat.providerName,
        serviceType: chat.serviceType,
        lastMessage: ChatMessage.fromJson(message.toJson()),
        createdAt: chat.createdAt,
        updatedAt: DateTime.now(),
        unreadCount: chat.unreadCount + 1,
        isActive: chat.isActive,
        status: chat.status,
      );
      _chatCache[message.chatId] = updatedChat;
      _refreshChatList();
    }
  }

  void _refreshChatList() {
    final chats = _chatCache.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _chatListStreamController.add(chats);
  }

  // Search functionality
  Future<List<MessageModel>> searchMessages(String query,
      {String? chatId}) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final url = chatId != null
          ? '${ApiConfig.baseUrl}/chats/$chatId/messages/search?q=$query'
          : '${ApiConfig.baseUrl}/messages/search?q=$query';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((message) => MessageModel.fromJson(message))
            .toList();
      }
      throw Exception('Failed to search messages');
    } catch (e) {
      throw Exception('Error searching messages: $e');
    }
  }

  // Media picker helpers
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  Future<File?> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    return result != null ? File(result.files.single.path!) : null;
  }

  void dispose() {
    _messageStreamController.close();
    _chatListStreamController.close();
    _typingStreamController.close();
    _onlineStatusStreamController.close();
  }
}
