import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/client.dart';
import '../../services/api_config.dart';

class ClientService {
  // The base URL will be set based on the device (emulator or real device)
  // Use ApiConfig.baseUrl for all requests. Device detection is handled globally.
  // Use ApiConfig.getEndpointUrl for all requests

  Future<Client> getClientData(String clientId) async {
    try {
      final url = ApiConfig.getEndpointUrl('clients/$clientId');

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
      Uri.parse(ApiConfig.getEndpointUrl('clients')),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Client.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load clients');
    }
  }
}
