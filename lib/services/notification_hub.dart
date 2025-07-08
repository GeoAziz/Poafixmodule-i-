import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/booking.dart';

class NotificationHub {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  // final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission for push notifications
    // await _messaging.requestPermission();

    // Initialize local notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(initSettings);

    // Handle incoming FCM messages
    // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    // FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  Future<void> _handleForegroundMessage(dynamic message) async {
    await showNotification(
      title: message['title'] ?? 'New Update',
      body: message['body'] ?? '',
      payload: message.toString(),
    );
  }

  void _handleBackgroundMessage(dynamic message) {
    print('Background message received: \\${message.toString()}');
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'service_updates',
        'Service Updates',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> showBookingNotification(Booking booking) async {
    String title = 'Booking Update';
    String body = 'You have a booking update.';
    // If BookingStatus is a String, use string comparison
    switch (booking.status) {
      case 'accepted':
        title = 'Booking Confirmed';
        body = 'Your service provider has confirmed your booking';
        break;
      case 'in_progress':
        title = 'Service Started';
        body = 'Your service provider has started working';
        break;
      case 'completed':
        title = 'Service Completed';
        body = 'Please proceed with payment';
        break;
      case 'pending':
        title = 'Booking Received';
        body = 'Your booking is being reviewed';
        break;
      case 'cancelled':
        title = 'Booking Cancelled';
        body = 'Your booking has been cancelled';
        break;
      case 'paid':
        title = 'Payment Received';
        body = 'Thank you for your payment';
        break;
      default:
        // Keep the default title/body
        break;
    }
    await showNotification(title: title, body: body);
  }
}
