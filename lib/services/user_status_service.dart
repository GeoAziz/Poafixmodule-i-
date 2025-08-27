import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class UserStatusService {
  static Future<Map<String, dynamic>?> fetchUserStatus(String userId) async {
    final url = ApiConfig.getApiUrl('users/$userId/status');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }
}
