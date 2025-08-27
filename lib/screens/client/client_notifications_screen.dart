import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/notification_service.dart';
import '../../services/websocket_service.dart';
import '../../models/notification_model.dart';
import '../payment/paypal_payment_screen.dart';
import '../../config/api_config.dart';

class ClientNotificationsScreen extends StatefulWidget {
  const ClientNotificationsScreen({super.key});

  @override
  _ClientNotificationsScreenState createState() =>
      _ClientNotificationsScreenState();
}

class _ClientNotificationsScreenState extends State<ClientNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  String? _error;
  List<NotificationModel> _notifications = [];
  String? _userId;

  int _getUnreadCount() {
    return _notifications.where((n) => !(n.read ?? false)).length;
  }

  @override
  void initState() {
    super.initState();
    _initUserIdAndFetch();
    _setupWebSocketListener();
  }

  void _setupWebSocketListener() async {
    final userId = await _getUserId();
    if (userId == null) return;
    final ws = WebSocketService();
    ws.connect(userId);
    ws.listen('notification', (data) {
      if (data['userId'] == userId) {
        print(
          '🔔 New notification received via WebSocket: ${data['notification']}',
        );
        _fetchNotifications();
      }
    });
  }

  Future<void> _initUserIdAndFetch() async {
    final userId = await _getUserId();
    setState(() {
      _userId = userId;
    });
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Initiating client notifications fetch...');
      // TODO: Replace with actual user ID from storage or auth
      final String? userId = await _getUserId();
      if (userId == null) throw Exception('User ID not found');
      final notifications = await _notificationService.getNotifications();

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
        print('Successfully loaded ${notifications.length} notifications');
      }
    } catch (e) {
      print('Error in _fetchNotifications: ${e.toString()}');
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _getUserId() async {
    // TODO: Replace with secure storage or auth provider in production
    return await Future.value('689dda4e522262694e34d873');
  }

  void _showPaymentPromptModal(
    BuildContext context,
    NotificationModel notification,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AnimatedPaymentPrompt(
        bookingId: notification.data?['bookingId']?.toString(),
        amount: notification.data?['amount'] ?? 0,
        onPayMpesa: () async {
          Navigator.pop(ctx);
          // Delay to ensure modal is closed before showing snackbar
          await Future.delayed(Duration(milliseconds: 200));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Initiating MPesa payment...')),
          );
          // TODO: Implement MPesa payment logic here
        },
        onPayPaypal: () async {
          Navigator.pop(ctx);
          // Delay to ensure modal is closed before showing snackbar and navigating
          await Future.delayed(Duration(milliseconds: 200));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Initiating PayPal payment...')),
          );
          try {
            debugPrint(
              '[Notifications] PayPal API URL: ' + ApiConfig.paypalPaymentUrl,
            );
            final paypalUri = Uri.parse(ApiConfig.paypalPaymentUrl);
            final response = await http.post(
              paypalUri,
              headers: {
                'Authorization':
                    'Bearer yourClientToken', // TODO: Use sandbox token in backend
                'Content-Type': 'application/json',
              },
              body: json.encode({
                'paymentId':
                    notification.data?['paymentId'] ?? 'fallback_payment_id',
                'amount': notification.data?['amount'],
                'bookingId': notification.data?['bookingId'],
                'clientId': notification.data?['clientId'] ?? _userId,
                'providerId': notification.data?['providerId'] ?? '',
              }),
            );
            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              final approvalUrl = data['approvalUrl'];
              // Ensure only sandbox URLs are used
              if (approvalUrl != null &&
                  approvalUrl.toString().contains('sandbox.paypal.com')) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => PaypalPaymentScreen(
                      approvalUrl: approvalUrl,
                      bookingId: notification.data?['bookingId'] ?? '',
                      amount: notification.data?['amount'] ?? 0.0,
                      paymentId: notification.data?['paymentId'] ?? '',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'PayPal sandbox approval URL not received. Check backend config.',
                    ),
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to initiate PayPal payment.'),
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
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
            )
          : _notifications.isEmpty
          ? Center(
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
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: _getUnreadCount() > 0
                            ? Container(
                                key: ValueKey<int>(_getUnreadCount()),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${_getUnreadCount()} Unread',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final icons = {
      'new_booking': Icons.book_online,
      'booking_update': Icons.update,
      'payment': Icons.payment,
      'system': Icons.system_update,
      'PAYMENT_REQUEST': Icons.payment,
    };

    final colors = {
      'new_booking': Colors.blue,
      'booking_update': Colors.orange,
      'payment': Colors.green,
      'system': Colors.purple,
      'PAYMENT_REQUEST': Colors.green,
    };

    // Debug: Log every notification rendered
    debugPrint(
      '[UI] Rendering notification: type=${notification.type}, title=${notification.title}, id=${notification.id}',
    );

    // For payment notifications, render a card and show payment prompt on tap
    if (notification.type.toLowerCase().contains('payment')) {
      debugPrint(
        '[UI] Rendering payment notification card for id=${notification.id}, type=${notification.type}',
      );
      return Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: (colors[notification.type] ?? Colors.green)
                .withOpacity(0.1),
            child: Icon(
              icons[notification.type] ?? Icons.payment,
              color: colors[notification.type] ?? Colors.green,
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
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          trailing: (notification.read ?? false)
              ? null
              : Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () {
            debugPrint(
              '[UI] Invoking payment modal for notification id=${notification.id}, type=${notification.type}',
            );
            _showPaymentPromptModal(context, notification);
          },
        ),
      );
    }

    // Fallback: Render unknown types as a generic card
    if (!icons.containsKey(notification.type)) {
      debugPrint(
        '[UI] Rendering fallback card for unknown type: ${notification.type}',
      );
      return Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.withOpacity(0.1),
            child: Icon(Icons.notifications, color: Colors.grey),
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
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          trailing: (notification.read ?? false)
              ? null
              : Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      );
    }

    // Default: Render known types as a card
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (colors[notification.type] ?? Colors.grey)
              .withOpacity(0.1),
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
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: (notification.read ?? false)
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
}

// Animated payment prompt widget
class _AnimatedPaymentPrompt extends StatefulWidget {
  final String? bookingId;
  final num? amount;
  final VoidCallback onPayMpesa;
  final VoidCallback onPayPaypal;

  const _AnimatedPaymentPrompt({
    this.bookingId,
    this.amount,
    required this.onPayMpesa,
    required this.onPayPaypal,
  });

  @override
  State<_AnimatedPaymentPrompt> createState() => _AnimatedPaymentPromptState();
}

class _AnimatedPaymentPromptState extends State<_AnimatedPaymentPrompt>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  final NotificationService _notificationService = NotificationService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildPaymentPrompt(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payment, size: 48, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Payment Required',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Amount: KES ${widget.amount ?? 0}',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.phone_android),
                    label: Text('Pay with MPesa'),
                    onPressed: widget.onPayMpesa,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.account_balance_wallet),
                    label: Text('Pay with PayPal'),
                    onPressed: widget.onPayPaypal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isLoading = true;
  String? _error;
  List<NotificationModel> _notifications = [];
  String? _userId;

  int _getUnreadCount() {
    return _notifications.where((n) => !(n.read ?? false)).length;
  }

  // Only keep the correct initState for animation controller

  void _setupWebSocketListener() async {
    final userId = await _getUserId();
    if (userId == null) return;
    final ws = WebSocketService();
    ws.connect(userId);
    ws.listen('notification', (data) {
      if (data['userId'] == userId) {
        print(
          '🔔 New notification received via WebSocket: ${data['notification']}',
        );
        _fetchNotifications();
      }
    });
  }

  Future<void> _initUserIdAndFetch() async {
    final userId = await _getUserId();
    setState(() {
      _userId = userId;
    });
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Initiating client notifications fetch...');
      // TODO: Replace with actual user ID from storage or auth
      final String? userId = await _getUserId();
      if (userId == null) throw Exception('User ID not found');
      final notifications = await _notificationService.getNotifications();

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
        print('Successfully loaded ${notifications.length} notifications');
      }
    } catch (e) {
      print('Error in _fetchNotifications: ${e.toString()}');
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _getUserId() async {
    // TODO: Replace with secure storage or auth provider in production
    return await Future.value('689dda4e522262694e34d873');
  }

  void _showPaymentPromptModal(
    BuildContext context,
    NotificationModel notification,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AnimatedPaymentPrompt(
        bookingId: notification.data?['bookingId']?.toString(),
        amount: notification.data?['amount'] ?? 0,
        onPayMpesa: () async {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Initiating MPesa payment...')),
          );
          // TODO: Implement MPesa payment logic here
        },
        onPayPaypal: () async {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Initiating PayPal payment...')),
          );
          try {
            debugPrint(
              '[Notifications] PayPal API URL: ' + ApiConfig.paypalPaymentUrl,
            );
            final paypalUri = Uri.parse(ApiConfig.paypalPaymentUrl);
            final response = await http.post(
              paypalUri,
              headers: {
                'Authorization':
                    'Bearer yourClientToken', // TODO: Use sandbox token in backend
                'Content-Type': 'application/json',
              },
              body: json.encode({
                'paymentId':
                    notification.data?['paymentId'] ?? 'fallback_payment_id',
                'amount': notification.data?['amount'],
                'bookingId': notification.data?['bookingId'],
                'clientId': notification.data?['clientId'] ?? _userId,
                'providerId': notification.data?['providerId'] ?? '',
              }),
            );
            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              final approvalUrl = data['approvalUrl'];
              // Ensure only sandbox URLs are used
              if (approvalUrl != null &&
                  approvalUrl.toString().contains('sandbox.paypal.com')) {
                // FIX: Always open in Flutter WebView, not external browser
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => PaypalPaymentScreen(
                      approvalUrl: approvalUrl,
                      bookingId: notification.data?['bookingId'] ?? '',
                      amount: notification.data?['amount'] ?? 0.0,
                      paymentId: notification.data?['paymentId'] ?? '',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'PayPal sandbox approval URL not received. Check backend config.',
                    ),
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to initiate PayPal payment.'),
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
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
            )
          : _notifications.isEmpty
          ? Center(
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
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: _getUnreadCount() > 0
                            ? Container(
                                key: ValueKey<int>(_getUnreadCount()),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${_getUnreadCount()} Unread',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final icons = {
      'new_booking': Icons.book_online,
      'booking_update': Icons.update,
      'payment': Icons.payment,
      'system': Icons.system_update,
      'PAYMENT_REQUEST': Icons.payment,
    };

    final colors = {
      'new_booking': Colors.blue,
      'booking_update': Colors.orange,
      'payment': Colors.green,
      'system': Colors.purple,
      'PAYMENT_REQUEST': Colors.green,
    };

    // Show modal payment prompt for payment notifications
    if (notification.type == 'payment' ||
        notification.type == 'PAYMENT_REQUEST') {
      return Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green.withOpacity(0.1),
            child: Icon(Icons.payment, color: Colors.green),
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
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          trailing: (notification.read ?? false)
              ? null
              : Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () => _showPaymentPromptModal(context, notification),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (colors[notification.type] ?? Colors.grey)
              .withOpacity(0.1),
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
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: (notification.read ?? false)
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
}
