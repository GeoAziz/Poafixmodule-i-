import 'package:flutter/material.dart';
import '../services/auth_storage.dart';
import '../screens/auth/login_screen.dart';

class AuthMiddleware {
  static Future<bool> checkAuth(BuildContext context) async {
    final authStorage = AuthStorage();
    final credentials = await authStorage.getCredentials();

    if (credentials['auth_token'] == null || credentials['user_id'] == null) {
      // Navigate to login if not authenticated
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
      return false;
    }
    return true;
  }
}
