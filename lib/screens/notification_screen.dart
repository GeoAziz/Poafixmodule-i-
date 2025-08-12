import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../services/websocket_service.dart';
import '../models/user_model.dart'; // Update import

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
      final userId = await _storage.read(key: 'userId');
      final userType = await _storage.read(key: 'userType');

      if (token == null || userId == null) {
        throw Exception('Authentication data missing');
      }

      print('Loading notifications for $userType: $userId');

      // Use ApiConfig.getEndpointUrl to construct the URL correctly
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications').replace(
          queryParameters: {
            'recipientId': userId,
            'recipientModel':
                userType == 'service-provider' ? 'Provider' : 'User',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Notifications response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;

        final notifications = data['data'] ?? [];
        setState(() {
          _notifications = List.from(notifications).map((notification) {
            // Extract the _doc content if it exists
            return notification['_doc'] ?? notification;
          }).toList()
            ..sort((a, b) => DateTime.parse(b['createdAt'] ?? '')
                .compareTo(DateTime.parse(a['createdAt'] ?? '')));
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load notifications');
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
    final DateTime createdAt =
        DateTime.tryParse(notification['createdAt'] ?? '') ?? DateTime.now();
    final bool isToday = DateTime.now().difference(createdAt).inDays == 0;
    final bool isRead = notification['read'] ?? false;
    final String type = notification['type']?.toString().toUpperCase() ?? '';
    final Map<String, dynamic> data = notification['data'] ?? {};

    // Get appropriate styling based on notification type
    final style = _getNotificationStyle(type);

    return Card(
      elevation: isRead ? 1 : 3,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isRead ? Colors.white : style.color.withOpacity(0.1),
      child: ListTile(
        leading: Icon(style.icon, color: style.color),
        title: Text(
          notification['title'] ?? 'Notification',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            color: style.color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message'] ?? ''),
            if (data['duration'] != null)
              Text(
                'Duration: ${data['duration']}',
                style: TextStyle(fontSize: 12),
              ),
            Text(
              isToday
                  ? 'Today at ${_formatTime(createdAt)}'
                  : _formatDate(createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: style.color,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  NotificationStyle _getNotificationStyle(String type) {
    switch (type.toUpperCase()) {
      case 'SYSTEM_ALERT':
      case 'ACCOUNT_BLOCKED':
        return NotificationStyle(Colors.red, Icons.block);
      case 'ACCOUNT_UNBLOCKED':
        return NotificationStyle(Colors.green, Icons.check_circle);
      case 'SYSTEM_WARNING':
        return NotificationStyle(Colors.orange, Icons.warning);
      default:
        return NotificationStyle(Colors.blue, Icons.notifications);
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Mark as read
    _markAsRead(notification['_id']);

    // Handle navigation based on notification type
    switch (notification['type']?.toUpperCase()) {
      case 'SUSPENSION':
        _showSuspensionDetails(notification);
        break;
      case 'UNSUSPENSION':
        _showUnsuspensionDetails(notification);
        break;
      case 'NEW_BOOKING':
        if (notification['data']?['bookingId'] != null) {
          // Navigate to booking details
          // Navigator.pushNamed(context, '/booking-details', arguments: notification['data']['bookingId']);
        }
        break;
    }
  }

  void _showSuspensionDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Account Suspended'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message'] ?? ''),
            SizedBox(height: 16),
            if (notification['data']?['duration'] != null)
              Text(
                'Duration: ${notification['data']['duration']}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 8),
            Text(
              'Suspended on: ${_formatDate(notification['createdAt'])}',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUnsuspensionDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suspension Lifted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message'] ?? ''),
            SizedBox(height: 8),
            Text(
              'Lifted on: ${_formatDate(notification['createdAt'])}',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
  final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      await http.patch(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'recipientModel': 'Provider' // Add this line
        }),
      );

      if (mounted) {
        await _loadNotifications();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}

class NotificationStyle {
  final Color color;
  final IconData icon;

  NotificationStyle(this.color, this.icon);
}
