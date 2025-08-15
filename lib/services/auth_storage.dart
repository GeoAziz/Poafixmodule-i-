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
    final token = await _storage.read(key: KEY_AUTH_TOKEN);
    String? userId = await _storage.read(key: KEY_USER_ID);
    // Fallback: check for 'userId' if 'user_id' is null
    if (userId == null) {
      userId = await _storage.read(key: 'userId');
    }
    final userType = await _storage.read(key: KEY_USER_TYPE);
    final name = await _storage.read(key: KEY_NAME);
    final email = await _storage.read(key: KEY_EMAIL);
    final businessName = await _storage.read(key: KEY_BUSINESS_NAME);
    final serviceType = await _storage.read(key: 'service_type');

    // Debug log
    print('Raw credentials from storage:');
    print('Token: $token');
    print('UserID: $userId');
    print('UserType: $userType');

    return {
      'auth_token': token,
      'user_id': userId,
      'userType': userType,
      'name': name,
      'email': email,
      'business_name': businessName,
      'service_type': serviceType,
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

  Future<String?> getToken() async {
    return await _storage.read(key: KEY_AUTH_TOKEN);
  }
}
