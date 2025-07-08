import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
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

      print('Initiating notifications fetch...');
      // Replace 'yourRecipientId' with actual user ID from storage or auth
      final String? userId = await _getUserId();
      if (userId == null) throw Exception('User ID not found');
      final notifications =
          await _notificationService.getNotifications(recipientId: userId);

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
        print('Successfully loaded \\${notifications.length} notifications');
      }
    } catch (e) {
      print('Error in _fetchNotifications: \\${e.toString()}');
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _getUserId() async {
    // Example: fetch from secure storage or auth provider
    // Replace with your actual logic
    // For demonstration, return a placeholder or fetch from storage
    // e.g., return await FlutterSecureStorage().read(key: 'userId');
    return await Future.value('provider_id');
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
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: $_error'),
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
            Text(
              'No notifications yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final icons = {
      'new_booking': Icons.book_online,
      'booking_update': Icons.update,
      'payment': Icons.payment,
      'system': Icons.system_update,
    };

    final colors = {
      'new_booking': Colors.blue,
      'booking_update': Colors.orange,
      'payment': Colors.green,
      'system': Colors.purple,
    };

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (colors[notification.type] ?? Colors.grey).withOpacity(0.1),
          child: Icon(
            icons[notification.type],
            color: colors[notification.type],
          ),
        ),
        title: Text(
          notification.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            SizedBox(height: 4),
            Text(
              timeago.format(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: (notification.read ?? false)
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),
        onTap: () {
          if ((notification.read ?? false) == false) {
            _notificationService.markAsRead(notification.id);
          }
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    final bookingId = notification.data?['bookingId'];
    if (notification.type == 'new_booking' && bookingId != null) {
      Navigator.pushNamed(
        context,
        '/booking-details',
        arguments: bookingId,
      );
    } else if (notification.type == 'booking_update' && bookingId != null) {
      Navigator.pushNamed(
        context,
        '/booking-details',
        arguments: bookingId,
      );
    }
  }
}
