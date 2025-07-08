import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart'; // Update this import
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/websocket.service.dart';
import '../../screens/rating/rating_screen.dart'; // Fix import path

class NotificationsScreen extends StatefulWidget {
  final User? user; // This now refers to user_model.dart
  const NotificationsScreen({Key? key, this.user}) : super(key: key);

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
        _notifications = notifications;
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

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'booking_accepted':
        return Icons.check_circle;
      case 'booking_rejected':
        return Icons.cancel;
      case 'booking_cancelled':
        return Icons.remove_circle;
      case 'job_started':
        return Icons.play_circle;
      case 'job_completed':
        return Icons.task_alt;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'booking_accepted':
        return Colors.green;
      case 'booking_rejected':
      case 'booking_cancelled':
        return Colors.red;
      case 'job_started':
        return Colors.blue;
      case 'job_completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
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

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type.toUpperCase()) {
      case 'BOOKING_ACCEPTED':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'BOOKING_REJECTED':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case 'BOOKING_REQUEST':
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case 'SYSTEM_ALERT':
        icon = Icons.warning;
        color = Colors.red;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.blue;
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildNotificationDetails(Map<String, dynamic> data) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['bookingId'] != null)
            _buildDetailRow('Booking ID', '#${data['bookingId']}'),
          if (data['status'] != null)
            _buildDetailRow('Status', data['status'].toString().toUpperCase()),
          if (data['amount'] != null)
            _buildDetailRow('Amount', 'KES ${data['amount']}'),
          if (data['scheduledDate'] != null)
            _buildDetailRow(
                'Scheduled',
                DateFormat('MMM dd, yyyy, hh:mm a')
                    .format(DateTime.parse(data['scheduledDate']))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityIcon(String type) {
    IconData icon;
    Color color;
    Color backgroundColor;

    switch (type) {
      case 'BOOKING_REQUEST':
        icon = Icons.schedule_send;
        color = Colors.blue;
        backgroundColor = Colors.blue[50]!;
        break;
      case 'BOOKING_ACCEPTED':
        icon = Icons.check_circle;
        color = Colors.green;
        backgroundColor = Colors.green[50]!;
        break;
      case 'BOOKING_REJECTED':
        icon = Icons.cancel;
        color = Colors.red;
        backgroundColor = Colors.red[50]!;
        break;
      case 'PAYMENT_RECEIVED':
        icon = Icons.payment;
        color = Colors.green;
        backgroundColor = Colors.green[50]!;
        break;
      case 'SERVICE_STARTED':
        icon = Icons.play_circle;
        color = Colors.blue;
        backgroundColor = Colors.blue[50]!;
        break;
      case 'SERVICE_COMPLETED':
        icon = Icons.task_alt;
        color = Colors.purple;
        backgroundColor = Colors.purple[50]!;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
        backgroundColor = Colors.grey[50]!;
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'accepted':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRowWithIcon(String label, dynamic value, IconData icon) {
    final displayValue = value?.toString() ?? 'Not specified';
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                displayValue,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      NotificationModel notification, Map<String, dynamic> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (data['bookingId'] != null)
          TextButton(
            onPressed: () => _navigateToBooking(data['bookingId']),
            child: Text('View Booking'),
          ),
        if (data['providerPhone'] != null)
          TextButton(
            onPressed: () => _contactProvider(data['providerPhone']),
            child: Text('Contact'),
          ),
      ],
    );
  }

  // Add these new methods
  void _navigateToBooking(String bookingId) {
    // Implement navigation to booking details
  }

  void _contactProvider(String phone) {
    // Implement provider contact functionality
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

  Future<void> _deleteNotification(String notificationId) async {
    // Implement delete functionality
  }

  NotificationStyle _getNotificationStyle(String type) {
    switch (type) {
      case 'BOOKING_REQUEST':
        return NotificationStyle(Colors.orange, Icons.schedule_send);
      case 'BOOKING_ACCEPTED':
        return NotificationStyle(Colors.green, Icons.check_circle);
      case 'BOOKING_REJECTED':
        return NotificationStyle(Colors.red, Icons.cancel);
      case 'BOOKING_CANCELLED':
        return NotificationStyle(Colors.grey, Icons.remove_circle);
      case 'PAYMENT_RECEIVED':
        return NotificationStyle(Colors.green, Icons.payment);
      case 'SERVICE_STARTED':
        return NotificationStyle(Colors.blue, Icons.play_circle);
      case 'SERVICE_COMPLETED':
        return NotificationStyle(Colors.purple, Icons.task_alt);
      case 'SYSTEM_ALERT':
        return NotificationStyle(Colors.red, Icons.warning);
      case 'ACCOUNT_BLOCKED':
        return NotificationStyle(Colors.red, Icons.block);
      case 'ACCOUNT_UNBLOCKED':
        return NotificationStyle(Colors.green, Icons.check_circle);
      default:
        return NotificationStyle(Colors.blue, Icons.notifications);
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildNotificationList(),
    );
  }
}

class NotificationStyle {
  final Color color;
  final IconData icon;

  NotificationStyle(this.color, this.icon);
}
