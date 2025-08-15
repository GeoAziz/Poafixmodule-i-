import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/client.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ClientService {
  // The base URL will be set based on the device (emulator or real device)
  Future<String> _getBaseUrl() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    // Check if the device is physical or emulator and return the appropriate URL
    if (androidInfo.isPhysicalDevice) {
      // For real devices, use your local machine's IP address
      return 'http:// 192.168.0.102/api/auth'; // Replace with your local IP
    } else {
      // For emulators, use 10.0.2.2 to point to the host machine
      return 'http://10.0.2.2:5000/api/auth';
    }
  }

  Future<Client> getClientData(String clientId) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = '$baseUrl/clients/$clientId';

      print("Request URL: $url"); // Log the request URL

      final response = await http.get(Uri.parse(url));

      print(
        "Response Status: ${response.statusCode}",
      ); // Log response status code
      print(
        "Response Body: ${response.body}",
      ); // Log the response body to check for errors

      if (response.statusCode == 200) {
        // Successful response, return the parsed data
        return Client.fromJson(jsonDecode(response.body));
      } else {
        // Log any non-200 response and provide a detailed exception
        print(
          'Error: Failed to load client data, Status Code: ${response.statusCode}',
        );
        print(
          'Response Body: ${response.body}',
        ); // Print the error response body
        throw Exception(
          'Failed to load client data: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // Log the error with more specific information
      print('Error: $e');
      throw Exception('Failed to load client data: $e');
    }
  }

  Future<List<Client>> getClients() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/clients'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Client.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load clients');
    }
  }
}
