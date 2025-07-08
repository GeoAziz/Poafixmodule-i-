import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/notification_model.dart';

class NotificationService {
  final _storage = const FlutterSecureStorage();
  WebSocketChannel? _channel;
  StreamController<List<NotificationModel>> _notificationStreamController =
      StreamController.broadcast();

  Stream<List<NotificationModel>> get notificationStream =>
      _notificationStreamController.stream;

  Stream<dynamic>? get socketStream => _channel?.stream;

  WebSocketChannel? get socket => _channel;

  // Add notification types
  static const String BOOKING_ACCEPTED = 'BOOKING_ACCEPTED';
  static const String BOOKING_REJECTED = 'BOOKING_REJECTED';
  static const String JOB_STARTED = 'JOB_STARTED';
  static const String JOB_COMPLETED = 'JOB_COMPLETED';

  Future<void> connectWebSocket() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception('No auth token found');

      final wsUrl = ApiConfig.baseUrl.replaceFirst('http', 'ws') + '/ws';
      print('🔗 Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['Authorization: Bearer $token'],
      );

      _channel?.stream.listen(
        (event) {
          print('📩 WebSocket event received: $event');
          final data = json.decode(event);

          // Handle different notification types
          switch (data['type']) {
            case BOOKING_ACCEPTED:
            case BOOKING_REJECTED:
              _handleBookingNotification(data['payload']);
              break;
            case JOB_STARTED:
            case JOB_COMPLETED:
              _handleJobNotification(data['payload']);
              break;
            default:
              _handleNewNotification(data['payload']);
          }
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
          _reconnectWebSocket();
        },
        onDone: () {
          print('🔌 WebSocket connection closed');
          _reconnectWebSocket();
        },
      );
    } catch (e) {
      print('❌ WebSocket connection error: $e');
      _reconnectWebSocket();
    }
  }

  Future<List<NotificationModel>> getNotifications({
    required String recipientId,
    String? recipientModel, // Make recipientModel optional
  }) async {
    try {
      final token = await _storage.read(key: 'token');
      final userType = await _storage.read(key: 'userType');
      if (token == null) {
        throw Exception('No auth token found');
      }

      // Map userType to correct recipientModel
      final effectiveRecipientModel = recipientModel ??
          (userType?.toLowerCase() == 'client' ? 'Client' : 'User');

      print('🔍 Fetching notifications with:');
      print('RecipientId: $recipientId');
      print('RecipientModel: $recipientModel');

      final response = await ApiConfig.httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications').replace(
          queryParameters: {
            'recipientId': recipientId,
            'recipientModel': effectiveRecipientModel,
          },
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final notifications = (data['data'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        print('📬 Parsed ${notifications.length} notifications');
        notifications.forEach((n) {
          print('📌 Notification: ${n.title} - ${n.message}');
        });

        return notifications;
      } else {
        throw Exception(
            'Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await ApiConfig.httpClient.patch(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }

      // Notify stream listeners to trigger UI update
      final notifications = await getNotifications(
        recipientId: await _storage.read(key: 'userId') ?? '',
        recipientModel: await _storage.read(key: 'userType') ?? 'User',
      );
      _notificationStreamController.add(notifications);
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: body,
        type: 'DOCUMENT',
        read: false,
        createdAt: DateTime.now(),
        recipientId: await _storage.read(key: 'userId') ?? '',
      );

      // Add to stream
      _notificationStreamController.add([notification]);

      // You might want to also persist this notification or show a system notification
      // Here's an example using a local notification plugin:
      // await flutterLocalNotificationsPlugin.show(
      //   0,
      //   title,
      //   body,
      //   NotificationDetails(
      //     android: AndroidNotificationDetails(
      //       'document_channel',
      //       'Document Notifications',
      //       importance: Importance.high,
      //       priority: Priority.high,
      //     ),
      //   ),
      //   payload: payload,
      // );
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  Future<void> createNotification(Map<String, dynamic> notificationData) async {
    try {
      final token = await _storage.read(key: 'token');
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(notificationData),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create notification');
      }
    } catch (e) {
      throw Exception('Error creating notification: $e');
    }
  }

  void _handleNewNotification(Map<String, dynamic> payload) {
    final notification = NotificationModel.fromJson(payload);
    _notificationStreamController.add([notification]);
  }

  void _handleBookingNotification(Map<String, dynamic> payload) {
    final notification = NotificationModel.fromJson({
      ...payload,
      'title': _getBookingTitle(payload['status']),
      'message': _getBookingMessage(payload),
      'type': 'BOOKING_UPDATE'
    });
    _notificationStreamController.add([notification]);
  }

  void _handleJobNotification(Map<String, dynamic> payload) {
    final notification = NotificationModel.fromJson({
      ...payload,
      'title': _getJobTitle(payload['status']),
      'message': _getJobMessage(payload),
      'type': 'JOB_UPDATE'
    });
    _notificationStreamController.add([notification]);
  }

  String _getBookingTitle(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Booking Accepted';
      case 'rejected':
        return 'Booking Rejected';
      case 'cancelled':
        return 'Booking Cancelled';
      default:
        return 'Booking Update';
    }
  }

  String _getBookingMessage(Map<String, dynamic> payload) {
    final status = payload['status'].toLowerCase();
    final serviceType = payload['serviceType'] ?? 'service';

    switch (status) {
      case 'accepted':
        return 'Your $serviceType booking has been accepted';
      case 'rejected':
        return 'Your $serviceType booking has been rejected';
      case 'cancelled':
        return 'Your $serviceType booking has been cancelled';
      default:
        return 'Your booking status has been updated to $status';
    }
  }

  String _getJobTitle(String status) {
    switch (status.toLowerCase()) {
      case 'started':
        return 'Job Started';
      case 'completed':
        return 'Job Completed';
      default:
        return 'Job Update';
    }
  }

  String _getJobMessage(Map<String, dynamic> payload) {
    final status = payload['status'].toLowerCase();
    final serviceType = payload['serviceType'] ?? 'service';

    switch (status) {
      case 'started':
        return 'Your $serviceType job has started';
      case 'completed':
        return 'Your $serviceType job has been completed';
      default:
        return 'Your job status has been updated to $status';
    }
  }

  Future<void> _reconnectWebSocket() async {
    await Future.delayed(Duration(seconds: 5));
    connectWebSocket();
  }

  void dispose() {
    _channel?.sink.close();
    _notificationStreamController.close();
  }
}
