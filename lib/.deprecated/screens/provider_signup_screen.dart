import 'package:flutter/material.dart';
import '../services/provider_service.dart';

class ProviderSignupScreen extends StatefulWidget {
  @override
  _ProviderSignupScreenState createState() => _ProviderSignupScreenState();
}

class _ProviderSignupScreenState extends State<ProviderSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _providerService = ProviderService();
  bool _isLoading = false;
  String? _error;

  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  // ...other controllers...

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _providerService.signup({
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        // ...other fields...
      });

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/provider-dashboard');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Provider Signup'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                validator: _validateEmail,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              // Add other form fields here
              if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                child:
                    _isLoading ? CircularProgressIndicator() : Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
