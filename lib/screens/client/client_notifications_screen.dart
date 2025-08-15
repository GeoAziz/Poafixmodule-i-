import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/bottomnavbar.dart';
import '../../widgets/client_sidepanel.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';

class ClientNotificationsScreen extends StatefulWidget {
  const ClientNotificationsScreen({super.key});

  @override
  _ClientNotificationsScreenState createState() =>
      _ClientNotificationsScreenState();
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade100,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.blueAccent, size: 28),
                SizedBox(width: 8),
                Text(
                  'Payment Required',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Please complete payment for this booking.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Amount: KES ${widget.amount?.toStringAsFixed(2) ?? '--'}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.phone_android),
                  label: Text('Pay with MPesa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: widget.onPayMpesa,
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.account_balance_wallet),
                  label: Text('Pay with PayPal'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: widget.onPayPaypal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
      // Replace 'yourRecipientId' with actual user ID from storage or auth
      final String? userId = await _getUserId();
      if (userId == null) throw Exception('User ID not found');
      final notifications = await _notificationService.getNotifications(
        recipientId: userId,
        recipientModel: 'client', // Use 'client' for client notifications
      );

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
    // Example: fetch from secure storage or auth provider
    // Replace with your actual logic
    // For demonstration, return a placeholder or fetch from storage
    // e.g., return await FlutterSecureStorage().read(key: 'userId');
    return await Future.value('client_id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      drawer: ClientSidePanel(
        user: User(
          id: _userId ?? '',
          name: '',
          email: '',
          userType: 'client',
          phone: '',
          token: '',
          avatarUrl: '',
        ),
        parentContext: context,
      ),
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
      bottomNavigationBar: FunctionalBottomNavBar(
        currentIndex: 4,
        unreadCount: _getUnreadCount(),
        onTap: (index) async {
          if (index == 4) return; // Already on notifications
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/select-service');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/bookings');
              break;
            case 3:
              // Fetch user from storage or provider
              final userId = await _getUserId();
              // You may want to fetch the full user object here. For now, pass a minimal User with required fields.
              Navigator.pushReplacementNamed(
                context,
                '/profile',
                arguments: User(
                  id: userId ?? '',
                  name: '',
                  email: '',
                  userType: 'client',
                  phone: '',
                  token: '',
                  avatarUrl: '',
                ),
              );
              break;
          }
        },
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

    // Show animated payment prompt for payment notifications
    if (notification.type == 'payment' ||
        notification.type == 'PAYMENT_REQUEST') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: _AnimatedPaymentPrompt(
          bookingId: notification.data?['bookingId']?.toString(),
          amount: notification.data?['amount'] ?? 0,
          onPayMpesa: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Initiating MPesa payment...')),
            );
            try {
              final response = await http.post(
                Uri.parse('https://your-api-url/api/payments/mpesa/initiate'),
                headers: {
                  'Authorization':
                      'Bearer yourClientToken', // Replace with actual token
                  'Content-Type': 'application/json',
                },
                body: json.encode({
                  'paymentId': notification.data?['paymentId'],
                  'amount': notification.data?['amount'],
                  'phoneNumber':
                      'clientPhoneNumber', // Replace with actual phone number
                  'bookingId': notification.data?['bookingId'],
                  'clientId': notification.data?['clientId'],
                  'providerId': notification.data?['providerId'],
                }),
              );
              if (response.statusCode == 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'STK push sent! Complete payment on your phone.',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to initiate MPesa payment.')),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
          onPayPaypal: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Initiating PayPal payment...')),
            );
            try {
              final response = await http.post(
                Uri.parse('https://your-api-url/api/payments/paypal/initiate'),
                headers: {
                  'Authorization':
                      'Bearer yourClientToken', // Replace with actual token
                  'Content-Type': 'application/json',
                },
                body: json.encode({
                  'paymentId': notification.data?['paymentId'],
                  'amount': notification.data?['amount'],
                  'bookingId': notification.data?['bookingId'],
                  'clientId': notification.data?['clientId'],
                  'providerId': notification.data?['providerId'],
                }),
              );
              if (response.statusCode == 200) {
                final data = json.decode(response.body);
                final approvalUrl = data['paypalResult']['approvalUrl'];
                if (approvalUrl != null) {
                  await launchUrl(Uri.parse(approvalUrl));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to get PayPal approval URL.'),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to initiate PayPal payment.')),
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
      Navigator.pushNamed(context, '/booking-details', arguments: bookingId);
    } else if (notification.type == 'booking_update' && bookingId != null) {
      Navigator.pushNamed(context, '/booking-details', arguments: bookingId);
    }
  }
}
