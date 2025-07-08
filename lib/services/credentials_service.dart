import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialsService {
  static final _storage = FlutterSecureStorage();

  static Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  static Future<String?> getUserType() async {
    return await _storage.read(key: 'user_type');
  }

  static Future<Map<String, String?>> getAllCredentials() async {
    return {
      'user_id': await _storage.read(key: 'user_id'),
      'user_type': await _storage.read(key: 'user_type'),
      'auth_token': await _storage.read(key: 'auth_token'),
      'user_name': await _storage.read(key: 'user_name'),
      'user_email': await _storage.read(key: 'user_email'),
      'business_name': await _storage.read(key: 'business_name'),
      'phone_number': await _storage.read(key: 'phone_number'),
    };
  }

  static Future<void> clearCredentials() async {
    await _storage.deleteAll();
  }

  static Future<bool> isLoggedIn() async {
    final userId = await getUserId();
    final userType = await getUserType();
    return userId != null && userType != null;
  }
}
