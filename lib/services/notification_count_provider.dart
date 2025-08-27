import 'package:flutter/material.dart';

class NotificationCountProvider extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void setCount(int value) {
    _count = value;
    notifyListeners();
  }

  void increment() {
    _count++;
    notifyListeners();
  }

  void reset() {
    _count = 0;
    notifyListeners();
  }
}
