import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    final service = NotificationService();

    test('getNotifications throws on missing token', () async {
      expect(
        () => service.getNotifications(recipientId: '', recipientModel: 'User'),
        throwsException,
      );
    });

    test('createNotification throws on missing recipientModel', () async {
      expect(
        () => service.createNotification({'recipientId': '123'}),
        throwsException,
      );
    });

    test('markAsRead throws on missing token', () async {
      expect(() => service.markAsRead('notif123'), throwsException);
    });

    // Add more tests for successful notification creation, marking as read, etc. with mocks
  });
}
