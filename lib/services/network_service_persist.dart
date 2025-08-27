import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  static const String _prefsKey = 'workingBaseUrl';
  String? _workingBaseUrl;
  List<ConnectivityResult>? _lastConnectivity;

  // Use dynamically discovered backend IP for all API calls
  String? get baseUrl => _workingBaseUrl;
  set baseUrl(String? url) {
    print('[NetworkService] Setting baseUrl: $url');
    _workingBaseUrl = url;
    _persistBaseUrl(url);
  }

  Future<void> loadPersistedBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _workingBaseUrl = prefs.getString(_prefsKey);
    print('[NetworkService] Loaded persisted baseUrl: $_workingBaseUrl');
  }

  Future<void> _persistBaseUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url != null) {
      await prefs.setString(_prefsKey, url);
      print('[NetworkService] Persisted baseUrl: $url');
    }
  }

  // ...existing code...
}
