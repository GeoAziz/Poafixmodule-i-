import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../screens/rating/rating_screen.dart'; // Update import path

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  late IO.Socket socket;

  factory WebSocketService() => _instance;

  WebSocketService._internal() {
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io(ApiConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('WebSocket Connected');
    });

    socket.onDisconnect((_) {
      print('WebSocket Disconnected');
    });

    socket.onError((err) {
      print('WebSocket Error: $err');
    });
  }

  void emit(String event, dynamic data) {
    try {
      socket.emit(event, data);
      print('WebSocket emitted event: $event with data: $data');
    } catch (e) {
      print('Error emitting WebSocket event: $e');
    }
  }

  void emitJobUpdate(String bookingId, String status, String providerId) {
    emit('job_status_update', {
      'bookingId': bookingId,
      'status': status,
      'providerId': providerId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void listen(String event, Function(dynamic) handler) {
    socket.on(event, handler);
  }

  void listenForRatingTrigger(BuildContext context) {
    socket.on('trigger_rating', (data) {
      print('📝 Rating trigger received: $data');
      if (data['bookingId'] != null && data['providerId'] != null) {
        // Use overlay to show rating screen
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => RatingScreen(
              bookingId: data['bookingId'],
              providerId: data['providerId'],
            ),
          ),
        );
      }
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}
