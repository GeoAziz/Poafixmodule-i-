import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../models/user_model.dart'; // Add this import
import '../services/websocket_service.dart';

class NotificationsScreen extends StatefulWidget {
  static const routeName = '/notifications';

  final User? user;

  const NotificationsScreen({Key? key, this.user}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _storage = FlutterSecureStorage();
  final _webSocketService = WebSocketService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupWebSocketListener();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
  final token = await _storage.read(key: 'auth_token');
      final serviceProviderId = await _storage.read(key: 'provider_id') ??
          await _storage.read(key: 'userId');

      if (token == null) throw Exception('No auth token found');
      if (serviceProviderId == null)
        throw Exception('No service provider ID found');

      print('Loading notifications for service provider: $serviceProviderId');

      // Updated URL to include provider ID as query parameter
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/notifications?providerId=$serviceProviderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'provider-id': serviceProviderId,
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;

        final notifications = data['data'] ?? [];
        print('Found ${notifications.length} notifications');

        setState(() {
          // Sort notifications by date, newest first
          _notifications = List.from(notifications)
            ..sort((a, b) => DateTime.parse(b['createdAt'])
                .compareTo(DateTime.parse(a['createdAt'])));
          _isLoading = false;
        });
      } else {
        throw Exception(
            'Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setupWebSocketListener() {
    _webSocketService.socket.on('new_notification', (data) {
      if (mounted) {
        _loadNotifications(); // Refresh notifications when new one arrives
      }
    });
  }

  @override
  void dispose() {
    _webSocketService.socket.off('new_notification');
    super.dispose();
  }

  Future<String?> _getToken() async {
    return widget.user?.token ?? await _storage.read(key: 'auth_token');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadNotifications,
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
            Text('Error: $_error'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(child: Text('No notifications'));
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final DateTime createdAt = DateTime.parse(notification['createdAt']);
    final bool isToday = DateTime.now().difference(createdAt).inDays == 0;
    final bool isRead = notification['read'] ?? false;

    // Enhanced message handling
    String message = notification['message'] ?? '';
    if (notification['data'] != null) {
      final data = notification['data'];
      if (data['status'] != null) {
        message = 'Booking status changed to: ${data['status']}';
      } else if (data['bookingId'] != null) {
        message = 'New booking #${data['bookingId']}';
      }
    }

    return Card(
      elevation: isRead ? 1 : 3,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isRead ? Colors.white : Colors.blue.shade50,
      child: ListTile(
        leading: _getNotificationIcon(notification['type']),
        title: Text(
          notification['title'] ?? 'Booking Update',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            Text(
              isToday
                  ? 'Today at ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
                  : _formatDate(notification['createdAt']),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Mark as read
    _markAsRead(notification['_id']);

    // Handle navigation based on notification type
    if (notification['type'] == 'NEW_BOOKING' &&
        notification['data']?['bookingId'] != null) {
      // Navigate to booking details
      // Navigator.pushNamed(context, '/booking-details', arguments: notification['data']['bookingId']);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
  final token = await _storage.read(key: 'auth_token');
      final serviceProviderId = await _storage.read(key: 'provider_id') ??
          await _storage.read(key: 'userId');
      if (token == null || serviceProviderId == null) return;

      await http.patch(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'recipient-id': serviceProviderId,
          'Content-Type': 'application/json',
        },
      );

      // Refresh notifications
      _loadNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  String _getBookingUpdateMessage(Map<String, dynamic>? data) {
    if (data == null) return '';

    final status = data['status'];
    final bookingId = data['bookingId'];

    return 'Booking #$bookingId ${status?.toLowerCase() ?? "updated"}';
  }

  Icon _getNotificationIcon(String? type) {
    switch (type?.toUpperCase()) {
      case 'BOOKING_UPDATE':
        return Icon(Icons.book_online, color: Colors.blue);
      case 'BOOKING_PAYMENT':
        return Icon(Icons.payment, color: Colors.green);
      case 'BOOKING_CANCEL':
        return Icon(Icons.cancel, color: Colors.red);
      default:
        return Icon(Icons.notifications, color: Colors.grey);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateStr;
    }
  }
}
