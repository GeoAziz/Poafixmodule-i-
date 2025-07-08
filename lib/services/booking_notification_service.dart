import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/booking.dart';

class BookingNotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iOS = DarwinInitializationSettings();
    final initSettings = InitializationSettings(android: android, iOS: iOS);

    await _notifications.initialize(initSettings);
  }

  Future<void> showBookingNotification(Booking booking) async {
    const androidDetails = AndroidNotificationDetails(
      'booking_channel',
      'Booking Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iOSDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _notifications.show(
      booking.hashCode,
      'Booking Update',
      'Your booking status has changed to: ${booking.status}',
      details,
    );
  }
}
