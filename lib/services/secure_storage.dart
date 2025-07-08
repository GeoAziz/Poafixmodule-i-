import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorage {
  final _storage = FlutterSecureStorage();
  final String _credentialsKey = 'user_credentials';

  Future<void> saveCredentials(Map<String, dynamic> credentials) async {
    await _storage.write(
      key: _credentialsKey,
      value: json.encode(credentials),
    );
  }

  Future<Map<String, dynamic>?> getCredentials() async {
    final data = await _storage.read(key: _credentialsKey);
    if (data != null) {
      return json.decode(data);
    }
    return null;
  }

  Future<void> deleteCredentials() async {
    await _storage.delete(key: _credentialsKey);
  }
}
