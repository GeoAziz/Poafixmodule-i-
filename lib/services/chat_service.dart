import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import 'websocket_service.dart';
import 'api_config.dart';

class ChatService {
  final _storage = FlutterSecureStorage();
  final WebSocketService _webSocketService = WebSocketService();
  
  // Get chat rooms for user
  Future<List<ChatRoom>> getChatRooms(String userId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/rooms/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((room) => ChatRoom.fromJson(room))
            .toList();
      } else {
        throw Exception('Failed to load chat rooms');
      }
    } catch (e) {
      throw Exception('Error loading chat rooms: $e');
    }
  }

  // Get or create chat room
  Future<ChatRoom> getOrCreateChatRoom({
    required String bookingId,
    required String clientId,
    required String providerId,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/rooms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'bookingId': bookingId,
          'clientId': clientId,
          'providerId': providerId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ChatRoom.fromJson(data['data']);
      } else {
        throw Exception('Failed to create chat room');
      }
    } catch (e) {
      throw Exception('Error creating chat room: $e');
    }
  }

  // Get messages for a chat room
  Future<List<ChatMessage>> getMessages({
    required String roomId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/rooms/$roomId/messages?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((message) => ChatMessage.fromJson(message))
            .toList();
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      throw Exception('Error loading messages: $e');
    }
  }

  // Send text message
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    String type = 'text',
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'roomId': roomId,
          'senderId': senderId,
          'content': content,
          'type': type,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final message = ChatMessage.fromJson(data['data']);
        
        // Emit via WebSocket for real-time delivery
        _webSocketService.emit('new_message', message.toJson());
        
        return message;
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // Send image message
  Future<ChatMessage> sendImageMessage({
    required String roomId,
    required String senderId,
    required File imageFile,
    String? caption,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/chat/messages/image'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['roomId'] = roomId;
      request.fields['senderId'] = senderId;
      if (caption != null) request.fields['caption'] = caption;
      
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final data = json.decode(responseBody);
        final message = ChatMessage.fromJson(data['data']);
        
        // Emit via WebSocket for real-time delivery
        _webSocketService.emit('new_message', message.toJson());
        
        return message;
      } else {
        throw Exception('Failed to send image');
      }
    } catch (e) {
      throw Exception('Error sending image: $e');
    }
  }

  // Send location message
  Future<ChatMessage> sendLocationMessage({
    required String roomId,
    required String senderId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

      return await sendMessage(
        roomId: roomId,
        senderId: senderId,
        content: json.encode(locationData),
        type: 'location',
      );
    } catch (e) {
      throw Exception('Error sending location: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead({
    required String roomId,
    required String userId,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/rooms/$roomId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'userId': userId}),
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get unread message count
  Future<int> getUnreadCount(String userId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/unread/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/chat/messages/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Error deleting message: $e');
    }
  }
}