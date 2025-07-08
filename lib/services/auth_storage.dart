import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static final AuthStorage _instance = AuthStorage._internal();
  factory AuthStorage() => _instance;
  AuthStorage._internal();

  final _storage = const FlutterSecureStorage();

  // Define constant keys to avoid typos
  static const String KEY_AUTH_TOKEN = 'auth_token';
  static const String KEY_USER_ID = 'user_id';
  static const String KEY_USER_TYPE = 'userType'; // Match the key used in login
  static const String KEY_NAME = 'name';
  static const String KEY_EMAIL = 'email';
  static const String KEY_BUSINESS_NAME = 'business_name';

  Future<void> saveCredentials({
    required String token,
    required String userId,
    required String userType, // Important: this matches the login response
    String? name,
    String? email,
    String? businessName,
    String? serviceType,
  }) async {
    print('Saving credentials:');
    print('Token: $token');
    print('UserID: $userId');
    print('UserType: $userType');

    await Future.wait([
      _storage.write(key: KEY_AUTH_TOKEN, value: token),
      _storage.write(key: KEY_USER_ID, value: userId),
      _storage.write(key: 'userId', value: userId), // Store both formats
      _storage.write(key: KEY_USER_TYPE, value: userType),
      if (name != null) _storage.write(key: KEY_NAME, value: name),
      if (email != null) _storage.write(key: KEY_EMAIL, value: email),
      if (businessName != null)
        _storage.write(key: KEY_BUSINESS_NAME, value: businessName),
      if (serviceType != null)
        _storage.write(key: 'serviceType', value: serviceType),
    ]);

    // Verify storage
    final storedId = await _storage.read(key: 'userId');
    print('Verified stored UserID: $storedId');

    print('Saved credentials - UserType: $userType, UserID: $userId');
  }

  Future<Map<String, String?>> getCredentials() async {
    final credentials = await Future.wait([
      _storage.read(key: KEY_AUTH_TOKEN),
      _storage.read(key: KEY_USER_ID),
      _storage.read(key: KEY_USER_TYPE),
      _storage.read(key: KEY_NAME),
      _storage.read(key: KEY_EMAIL),
      _storage.read(key: KEY_BUSINESS_NAME),
    ]);

    // Debug log
    print('Raw credentials from storage:');
    print('Token: ${credentials[0]}');
    print('UserID: ${credentials[1]}');
    print('UserType: ${credentials[2]}');

    return {
      'auth_token': credentials[0],
      'user_id': credentials[1],
      'userType': credentials[2], // This matches the key used in login response
      'name': credentials[3],
      'email': credentials[4],
      'business_name': credentials[5],
      'service_type': await _storage.read(key: 'service_type'),
    };
  }

  Future<void> clearCredentials() async {
    await _storage.deleteAll();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      final token = await _storage.read(key: KEY_AUTH_TOKEN);
      if (token == null) throw Exception('Not authenticated');

      // Update local storage
      await Future.wait([
        if (updates['name'] != null)
          _storage.write(key: KEY_NAME, value: updates['name']),
        if (updates['email'] != null)
          _storage.write(key: KEY_EMAIL, value: updates['email']),
        if (updates['phoneNumber'] != null)
          _storage.write(key: 'phone_number', value: updates['phoneNumber']),
        if (updates['businessName'] != null)
          _storage.write(
              key: KEY_BUSINESS_NAME, value: updates['businessName']),
      ]);

      // TODO: Add API call to update backend
      // final response = await http.patch(
      //   Uri.parse('${ApiConfig.baseUrl}/profile'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //   },
      //   body: json.encode(updates),
      // );
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await _storage.read(key: KEY_AUTH_TOKEN);
      if (token == null) throw Exception('Not authenticated');

      // TODO: Add API call to change password
      // final response = await http.post(
      //   Uri.parse('${ApiConfig.baseUrl}/change-password'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //   },
      //   body: json.encode({
      //     'currentPassword': currentPassword,
      //     'newPassword': newPassword,
      //   }),
      // );
    } catch (e) {
      print('Error changing password: $e');
      rethrow;
    }
  }
}
