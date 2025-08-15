import 'package:flutter/material.dart';

class NotificationCountProvider extends ChangeNotifier {
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  void setUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  void increment() {
    _unreadCount++;
    notifyListeners();
  }

  void decrement() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  void markAllRead() {
    _unreadCount = 0;
    notifyListeners();
  }
}
