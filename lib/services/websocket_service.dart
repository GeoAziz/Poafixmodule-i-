import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import '../config/api_config.dart';
import 'package:flutter/material.dart';
import '../screens/rating/rating_screen.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  late IO.Socket socket;
  final _storage = FlutterSecureStorage();
  final _connectionStatusController = StreamController<bool>.broadcast();
  final _bookingController = StreamController<Map<String, dynamic>>.broadcast();
  bool isConnected = false;
  int _retryCount = 0;
  static const int maxRetries = 3;
  bool _isDisposed = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  Stream<bool> get connectionStream => _connectionStatusController.stream;
  Stream<Map<String, dynamic>> get bookingStream => _bookingController.stream;

  WebSocketService._internal() {
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io(ApiConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.onConnect((_) {
      print('WebSocket Connected');
      isConnected = true;
      _retryCount = 0;
      _connectionStatusController.add(true);
      _startPingTimer();
    });

    socket.onDisconnect((_) {
      print('WebSocket Disconnected');
      isConnected = false;
      _connectionStatusController.add(false);
      _pingTimer?.cancel();
      _handleConnectionError();
    });

    socket.onConnectError((error) {
      print('Connection Error: $error');
      _handleConnectionError();
    });

    socket.onError((error) {
      print('Socket Error: $error');
      _handleConnectionError();
    });

    // Listen for booking events
    socket.on('booking_update', (data) {
      print('Booking update received: $data');
      _bookingController.add(data);
    });

    socket.on('booking_cancelled', (data) {
      print('Booking cancelled: $data');
      _bookingController.add({'type': 'cancelled', 'data': data});
    });

    // Add ping/pong for connection health check
    socket.on('pong', (_) {
      print('Received pong from server');
    });

    // Set up periodic ping
    Timer.periodic(Duration(seconds: 25), (_) {
      if (isConnected) {
        socket.emit('ping');
      }
    });

    // Add suspension event handlers
    socket.on('provider_suspended', (data) {
      print('Received suspension notification: $data');
    });

    socket.on('provider_unsuspended', (data) {
      print('Received unsuspension notification: $data');
    });
  }

  Future<void> connect(String userId) async {
    print('Disconnecting existing socket connection');
    socket.disconnect();

    try {
      print('Connecting to WebSocket with ID: $userId');
      print('URL: ${ApiConfig.baseUrl}');

      socket.io.options?['query'] = {'userId': userId};
      socket.connect();
    } catch (e) {
      print('Error initializing socket: $e');
      _handleConnectionError();
    }
  }

  void _handleConnectionError() {
    isConnected = false;
    _connectionStatusController.add(false);

    if (_retryCount < maxRetries) {
      _retryCount++;
      print('Attempting reconnection #$_retryCount');

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(Duration(seconds: _retryCount * 2), () async {
        final userId = await _storage.read(key: 'userId');
        if (userId != null) {
          connect(userId);
        }
      });
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (socket.connected) {
        socket.emit('ping');
      }
    });
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 5), () {
      if (!socket.connected && !_isDisposed) {
        print('🔄 Attempting to reconnect...');
        socket.connect();
      }
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    socket.disconnect();
    isConnected = false;
    _connectionStatusController.add(false);
    _bookingController.close();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    socket.dispose();
    _connectionStatusController.close();
  }

  void registerProvider(String providerId) {
    socket.emit('registerProvider', providerId);
  }

  void listenForRatingTrigger(BuildContext context) {
    socket.on('trigger_rating', (data) {
      print('📝 Rating trigger received: $data');
      final bookingId = data['bookingId'];
      final providerId = data['providerId'];

      // Show rating screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RatingScreen(
            bookingId: bookingId,
            providerId: providerId,
          ),
        ),
      );
    });
  }

  void emitJobUpdate(String bookingId, String status, String providerId) {
    socket.emit('job_status_update', {
      'bookingId': bookingId,
      'status': status,
      'providerId': providerId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void emitRatingSubmitted(String providerId, double rating) {
    socket.emit('rating_submitted', {
      'providerId': providerId,
      'rating': rating,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void listen(String event, Function(dynamic) handler) {
    socket.on(event, (data) {
      print('🔔 Received $event: $data');
      handler(data);
    });
  }
}
