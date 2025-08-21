import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _storage = const FlutterSecureStorage();
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  int _currentIndex = 0; // For bottom nav

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
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      final userId = await _storage.read(key: 'userId');
      final userType = await _storage.read(key: 'userType');

      if (token == null || userId == null) {
        throw Exception('Authentication required');
      }

      print('📱 Loading notifications for user: $userId (type: $userType)');

      // Remove recipientId and recipientModel parameters, just call getNotifications()
      final notifications = await _notificationService.getNotifications();

      if (mounted) {
        setState(() {
          _notifications = notifications; // Updated to use _notifications
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupWebSocketListener() {
    _notificationService.connectWebSocket();
    _notificationService.socket?.stream.listen((event) {
      print('📩 New notification received');
      _loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadNotifications),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationsList(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Handle navigation
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/search');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/bookings');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Bookings'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildNotificationsList() {
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

  Widget _buildNotificationCard(NotificationModel notification) {
    Color backgroundColor;
    IconData icon;
    Color textColor;

    // Enhanced notification styling based on type
    switch (notification.type.toUpperCase()) {
      case 'ACCOUNT_BLOCKED':
        backgroundColor = Colors.red.shade50;
        icon = Icons.block;
        textColor = Colors.red;
        break;
      case 'ACCOUNT_UNBLOCKED':
        backgroundColor = Colors.green.shade50;
        icon = Icons.check_circle;
        textColor = Colors.green;
        break;
      default:
        backgroundColor = Colors.blue.shade50;
        icon = Icons.notifications;
        textColor = Colors.blue;
    }

    return Card(
      color: backgroundColor,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(
          notification.title,
          style: TextStyle(
            color: textColor,
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: notification.isRead ? null : _buildUnreadIndicator(textColor),
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  Widget _buildUnreadIndicator(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  String _formatDate(DateTime date) {
    // Implement date formatting logic
    return date.toString();
  }

  void _handleNotificationTap(NotificationModel notification) {
    _notificationService.markAsRead(notification.id);

    // Navigate directly to bookings screen
    if (notification.type.contains('BOOKING')) {
      Navigator.pushReplacementNamed(context, '/bookings');
    }
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}
