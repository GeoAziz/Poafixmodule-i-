import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_storage.dart';
import '../../config/api_config.dart'; // Add this import
import '../home/home_screen.dart'; // Import HomeScreen

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _authStorage = AuthStorage();
  final _formKey = GlobalKey<FormState>();
  String? _email, _password, _name, _businessName, _serviceType;

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        // Use proper API endpoint from config
        final response = await http.post(
          Uri.parse(
              '${ApiConfig.baseUrl}/providers/signup'), // Updated endpoint
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': _email,
            'password': _password,
            'name': _name,
            'businessName': _businessName,
            'serviceType': _serviceType,
            'location': {
              // Add location field
              'type': 'Point',
              'coordinates': [0, 0] // Default coordinates, update as needed
            }
          }),
        );

        print('Signup response status: ${response.statusCode}'); // Debug log
        print('Signup response body: ${response.body}'); // Debug log

        if (response.statusCode == 201) {
          final data = json.decode(response.body);

          // Save credentials after successful signup
          await _authStorage.saveCredentials(
            token: data['token'],
            userId: data['user']['id'],
            userType: data['userType'],
            name: data['user']['name'],
            email: data['user']['email'],
            businessName: data['user']['businessName'],
            serviceType: data['user']['serviceType'],
          );

          // Navigate to appropriate screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => HomeScreen(user: data['user'])),
          );
        } else {
          final errorData = json.decode(response.body);
          _showError(errorData['error'] ?? 'Failed to sign up');
        }
      } catch (e) {
        print('Signup error: $e'); // Debug log
        _showError('Network error: Please check your connection');
      }
    }
  }

  void _showError(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(error),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
                onSaved: (value) => _email = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                onSaved: (value) => _password = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Business Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your business name';
                  }
                  return null;
                },
                onSaved: (value) => _businessName = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Service Type'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your service type';
                  }
                  return null;
                },
                onSaved: (value) => _serviceType = value,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleSignUp,
                child: Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
