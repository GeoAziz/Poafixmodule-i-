import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart'; // Update this import
import '../../widgets/client_sidepanel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/websocket.service.dart';
import '../../screens/rating/rating_screen.dart'; // Fix import path

class NotificationsScreen extends StatefulWidget {
  final User? user; // This now refers to user_model.dart
  const NotificationsScreen({super.key, this.user});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  final WebSocketService _webSocketService = WebSocketService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  late AnimationController _refreshIconController;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeLocalNotifications();
    _loadNotifications();
    _setupWebSocketListener();
    _setupWebSocket();
  }

  void _setupAnimations() {
    _refreshIconController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotifications.initialize(initializationSettings);
  }

  void _setupWebSocketListener() {
    _notificationService.notificationStream.listen((notifications) async {
      setState(() {
        _notifications = notifications;
      });

      // Handle block notifications
      final latestNotification = notifications.first;
      if (latestNotification.type == 'ACCOUNT_BLOCKED' ||
          latestNotification.type == 'ACCOUNT_UNBLOCKED') {
        _handleBlockStatusChange(latestNotification);
      }

      // Vibrate and show local notification
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200);
      }

      _showLocalNotification(notifications.first);
      _refreshIconController.forward(from: 0.0);
    });

    _webSocketService.socket.on('trigger_rating', (data) {
      if (!mounted) return;

      final bookingId = data['bookingId'];
      final providerId = data['providerId'];

      // Show rating dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => RatingScreen(
          bookingId: bookingId,
          providerId: providerId,
        ),
      );
    });
  }

  void _handleBlockStatusChange(NotificationModel notification) {
    if (notification.data != null) {
      final bool isBlocked = notification.type == 'ACCOUNT_BLOCKED';
      final String userId = notification.data!['userId'] ?? '';
      final String reason = notification.data!['reason'] ?? '';

      // Update local state if needed
      setState(() {
        // Update any UI elements that show block status
      });

      // Show appropriate message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBlocked
              ? 'Account has been blocked: $reason'
              : 'Account has been unblocked'),
          backgroundColor: isBlocked ? Colors.red : Colors.green,
        ),
      );
    }
  }

  void _setupWebSocket() {
    WebSocketService().listen('booking_update', (data) {
      _handleNewNotification(NotificationModel.fromJson(data));
    });
  }

  void _handleNewNotification(NotificationModel notification) {
    setState(() {
      _notifications.insert(0, notification);
    });
  }

  Future<void> _showLocalNotification(NotificationModel notification) async {
    const androidDetails = AndroidNotificationDetails(
      'notifications_channel',
      'Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      0,
      notification.title,
      notification.message,
      details,
    );
  }

  Future<void> _loadNotifications() async {
    try {
      print('🔄 Loading notifications...');
      final storage = FlutterSecureStorage();
      final userId = widget.user?.id ?? await storage.read(key: 'userId');

      print('👤 User ID: $userId');

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final notifications = await _notificationService.getNotifications(
        recipientId: userId,
        recipientModel: widget.user?.userType ?? 'User',
      );

      print('📥 Received ${notifications.length} notifications');

      if (!mounted) return;

      setState(() {
        // Deduplicate notifications based on their ID
        final notificationIds = _notifications.map((n) => n.id).toSet();
        _notifications = [
          ..._notifications,
          ...notifications.where((n) => !notificationIds.contains(n.id)),
        ];
        _isLoading = false;
      });

      print('🔄 State updated with notifications');
    } catch (e) {
      print('❌ Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Show error state
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load notifications: $e')),
          );
        });
      }
    }
  }

  String _getGroupTitle(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return DateFormat('EEEE').format(date);
    return DateFormat('MMMM d, y').format(date);
  }

  Widget _buildNotificationList() {
    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return GroupedListView<NotificationModel, String>(
      elements: _notifications,
      groupBy: (notification) => _getGroupTitle(notification.createdAt),
      groupSeparatorBuilder: (groupTitle) => Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          groupTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ),
      itemBuilder: (context, notification) {
        // Add null check before building card
        return _buildNotificationCard(notification);
      },
      useStickyGroupSeparators: true,
      order: GroupedListOrder.DESC,
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    print('🎯 Building card for notification:');
    print('Title: ${notification.title}');
    print('Message: ${notification.message}');
    print('Data: ${notification.data}');

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Keep existing header code
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (notification.read == false)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content - Updated middle section
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),

                // Booking details if available
                if (notification.data != null && notification.data!.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (notification.data!['bookingId'] != null)
                          Row(
                            children: [
                              Icon(Icons.bookmark_border,
                                  size: 16, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text(
                                'Booking ID: ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '#${notification.data!['bookingId'].toString().substring(0, 8)}',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        if (notification.data!['status'] != null) ...[
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 16, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text(
                                'Status: ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                notification.data!['status']
                                    .toString()
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(
                                      notification.data!['status']),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Footer - Keep existing footer code
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getTimeAgo(notification.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                if (notification.read == false)
                  TextButton.icon(
                    onPressed: () => _markAsRead(notification.id),
                    icon: Icon(Icons.check_circle_outline),
                    label: Text('Mark as Read'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty_notifications.json',
            width: 200,
            height: 200,
          ),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your notifications will appear here',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Try:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('• Booking a service'),
          Text('• Completing a job'),
          Text('• Checking your schedule'),
        ],
      ),
    );
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      _loadNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  }

  @override
  void dispose() {
    _refreshIconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        // Do not override leading so drawer icon appears
        actions: [
          RotationTransition(
            turns: Tween(begin: 0.0, end: 1.0).animate(_refreshIconController),
            child: IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadNotifications,
            ),
          ),
        ],
      ),
      drawer: ClientSidePanel(user: widget.user ?? User(id: '', name: '', email: '', userType: ''), parentContext: context),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildNotificationList(),
    );
  }
}

class ProviderNotificationsScreen extends StatefulWidget {
  const ProviderNotificationsScreen({super.key});

  @override
  _ProviderNotificationsScreenState createState() =>
      _ProviderNotificationsScreenState();
}

class _ProviderNotificationsScreenState
    extends State<ProviderNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;

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

      final userId = await _notificationService.getUserId();
      final notifications = await _notificationService.getNotifications(
        recipientId: userId,
        recipientModel: 'Provider',
      );

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_notifications.isEmpty) {
      return Center(child: Text('No notifications available'));
    }

    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return ListTile(
          title: Text(notification.title),
          subtitle: Text(notification.message),
        );
      },
    );
  }
}
