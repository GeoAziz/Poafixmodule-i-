import 'package:flutter/material.dart';

class NavigationService {
  static void navigateToNotifications(BuildContext context) {
    print('Navigating to notifications screen...');
    Navigator.pushNamed(context, '/notifications');
  }
}
