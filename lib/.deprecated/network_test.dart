import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NetworkTest extends StatefulWidget {
  @override
  _NetworkTestState createState() => _NetworkTestState();
}

class _NetworkTestState extends State<NetworkTest> {
  Future<void> _makeRequest() async {
    final response = await http
        .get(Uri.parse('https://jsonplaceholder.typicode.com/todos/1'));

    if (response.statusCode == 200) {
      print('Request successful!');
    } else {
      print('Request failed!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Network Test'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _makeRequest,
          child: Text('Make Request'),
        ),
      ),
    );
  }
}
