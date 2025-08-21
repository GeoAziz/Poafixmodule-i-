import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../models/notification.dart';
import 'package:http/http.dart' as http;

class ClientNotificationsScreen extends StatefulWidget {
  const ClientNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<ClientNotificationsScreen> createState() =>
      _ClientNotificationsScreenState();
}

class _ClientNotificationsScreenState extends State<ClientNotificationsScreen> {
  late WebSocketChannel channel;
  List<NotificationModel> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _fetchNotifications();
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  void _connectWebSocket() async {
    final token = await getAuthToken();
    final userId = await getUserId(); // Implement this method to get user ID
    final wsUrl = Uri.parse(
      '${ApiConfig.baseUrl.replaceFirst('http', 'ws')}/socket.io/?token=$token',
    );

    channel = WebSocketChannel.connect(wsUrl);

    // Register user ID with WebSocket
    channel.sink.add(json.encode({'type': 'register', 'userId': userId}));

    channel.stream.listen(
      (message) {
        final data = json.decode(message);
        if (data['type'] == 'NEW_NOTIFICATION') {
          setState(() {
            notifications.insert(0, NotificationModel.fromJson(data['data']));
          });

          // Show snackbar for payment notifications
          if (data['data']['type'] == 'PAYMENT_COMPLETED') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment completed successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        // Implement retry logic here
      },
    );
  }

  Future<void> _fetchNotifications() async {
    try {
      final token = await getAuthToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          notifications = (data['data'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (error) {
      print('Error fetching notifications: $error');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading notifications')));
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final token = await getAuthToken();
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'read': true}),
      );
    } catch (error) {
      print('Error marking notification as read: $error');
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchNotifications),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? Center(child: Text('No notifications'))
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Dismissible(
                    key: Key(notification.id),
                    onDismissed: (_) async {
                      await _markAsRead(notification.id);
                      setState(() {
                        notifications.removeAt(index);
                      });
                    },
                    background: Container(
                      color: Colors.green,
                      child: Icon(Icons.check, color: Colors.white),
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 20),
                    ),
                    child: NotificationTile(notification: notification),
                  );
                },
              ),
            ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const NotificationTile({Key? key, required this.notification})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _getNotificationIcon(),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(notification.message),
      trailing: Text(
        _formatTimestamp(notification.createdAt),
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _getNotificationIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'PAYMENT_COMPLETED':
        iconData = Icons.payment;
        iconColor = Colors.green;
        break;
      case 'PAYMENT_CANCELLED':
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.blue;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.1),
      child: Icon(iconData, color: iconColor),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
