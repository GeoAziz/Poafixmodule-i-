import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesTestScreen extends StatefulWidget {
  @override
  _PreferencesTestScreenState createState() => _PreferencesTestScreenState();
}

class _PreferencesTestScreenState extends State<PreferencesTestScreen> {
  String _status = 'No value stored yet';

  @override
  void initState() {
    super.initState();
    _checkSharedPreferences();
  }

  Future<void> _checkSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    String? clientId = prefs.getString('client_id');
    setState(() {
      _status =
          clientId != null ? 'Client ID: $clientId' : 'No client ID found';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SharedPreferences Test')),
      body: Center(
        child: Text(
          _status,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
