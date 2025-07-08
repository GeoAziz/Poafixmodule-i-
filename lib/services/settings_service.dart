import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/provider_settings.dart';
import '../services/auth_storage.dart';

class SettingsService {
  final AuthStorage _authStorage = AuthStorage();
  final _storage = FlutterSecureStorage();
  final String _settingsCacheKey = 'provider_settings';

  Future<ProviderSettings> getSettings() async {
    try {
      final credentials = await _authStorage.getCredentials();
      final token = credentials['auth_token'];
      final providerId = credentials['user_id'];
      final userType = credentials['userType'];

      if (token == null || providerId == null) {
        throw Exception('Not authenticated');
      }

      if (userType != 'provider') {
        throw Exception('Invalid user type. Provider access required.');
      }

      print('Fetching settings for provider: $providerId');
      print('Using token: $token');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/settings/$providerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      print('Settings response status: ${response.statusCode}');
      print('Settings response body: ${response.body}');

      if (response.statusCode == 200) {
        final settings = ProviderSettings.fromJson(json.decode(response.body));
        await _storage.write(
          key: _settingsCacheKey,
          value: json.encode(settings.toJson()),
        );
        return settings;
      }

      // Try to get cached settings if request fails
      final cachedSettings = await _storage.read(key: _settingsCacheKey);
      if (cachedSettings != null) {
        print('Using cached settings');
        return ProviderSettings.fromJson(json.decode(cachedSettings));
      }

      throw Exception('Failed to load settings');
    } catch (e) {
      print('Error in getSettings: $e');
      rethrow;
    }
  }

  Future<void> updateSettings(ProviderSettings settings) async {
    try {
      final credentials = await _authStorage.getCredentials();
      final token = credentials['auth_token'];

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/settings/${settings.providerId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(settings.toJson()),
      );

      if (response.statusCode == 200) {
        await _storage.write(
          key: _settingsCacheKey,
          value: json.encode(settings.toJson()),
        );
      } else {
        throw Exception('Failed to update settings');
      }
    } catch (e) {
      print('Error updating settings: $e');
      rethrow;
    }
  }
}
