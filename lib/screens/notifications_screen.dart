import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  String? _error;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔄 Refreshing notifications...');
      // TODO: Replace 'yourRecipientId' with the actual recipient ID as needed
      // For now, set a placeholder or fetch the userId from your authentication logic
      final String userId =
          'yourRecipientId'; // Replace with actual user ID retrieval
      // TODO: Replace with actual recipientModel instance as needed
      final recipientModel = null; // Replace with actual recipientModel object
      final notifications = await _notificationService.getNotifications(
        recipientId: userId,
        recipientModel: recipientModel,
      );
      print('✅ Received ${notifications.length} notifications');

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          _getIconForType(notification.type),
          color: _getColorForType(notification.type),
          size: 28,
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: (notification.read ?? false)
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(notification.message),
            SizedBox(height: 4),
            Text(
              timeago.format(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'NEW_BOOKING':
        return Icons.calendar_today;
      case 'STATUS_UPDATE':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'NEW_BOOKING':
        return Colors.blue;
      case 'STATUS_UPDATE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    if (!(notification.read ?? true)) {
      try {
        await _notificationService.markAsRead(notification.id);
        // Refresh notifications after marking as read
        _fetchNotifications();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark notification as read')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: _fetchNotifications,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No notifications yet'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationItem(_notifications[index]);
        },
      ),
    );
  }
}
