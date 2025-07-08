import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:poafix/config/api_config.dart';
import 'package:poafix/models/notification_model.dart';
import 'package:poafix/services/notification_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  final _storage = const FlutterSecureStorage();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
    _fetchNotifications();
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    final userId = await _storage.read(key: 'userId');
    if (userId != null) {
      await _notificationService.connectSocket(userId);
      _notificationService.socket?.on('newNotification', (data) {
        _fetchNotifications();
      });
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> notificationsJson = json.decode(response.body);
        setState(() {
          _notifications = notificationsJson
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/$notificationId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'isRead': true}),
      );
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'No notifications',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: notification.isRead
                                  ? Colors.grey
                                  : Theme.of(context).primaryColor,
                              child: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(notification.description),
                            trailing: Text(
                              _formatTimestamp(notification.timestamp),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            onTap: () async {
                              await _markAsRead(notification.id);
                              // Handle navigation to booking details if needed
                              if (notification.bookingId != null) {
                                // Navigate to booking details
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  void dispose() {
    _notificationService.disconnectSocket();
    _animationController.dispose();
    super.dispose();
  }
}
