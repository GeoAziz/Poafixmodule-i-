import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  Timer? _keepAliveTimer;
  Timer? _activityCheckTimer;
  DateTime? _lastActivity;
  bool _isActive = false;

  Future<void> startSession() async {
    try {
      final token = await AuthService().getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/session/start'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _isActive = true;
        _lastActivity = DateTime.now();
        _startKeepAliveTimer();
        _startActivityCheck();
      }
    } catch (e) {
      print('Error starting session: $e');
    }
  }

  Future<void> endSession() async {
    try {
      final token = await AuthService().getToken();
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/session/end'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      print('Error ending session: $e');
    } finally {
      _stopTimers();
      _isActive = false;
    }
  }

  void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(Duration(minutes: 5), (_) => _keepAlive());
  }

  void _startActivityCheck() {
    _activityCheckTimer?.cancel();
    _activityCheckTimer = Timer.periodic(Duration(minutes: 1), (_) {
      if (_lastActivity != null &&
          DateTime.now().difference(_lastActivity!) > Duration(minutes: 30)) {
        endSession();
      }
    });
  }

  Future<void> _keepAlive() async {
    try {
      final token = await AuthService().getToken();
      await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/session/keep-alive'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      _lastActivity = DateTime.now();
    } catch (e) {
      print('Error in keep-alive: $e');
    }
  }

  void _stopTimers() {
    _keepAliveTimer?.cancel();
    _activityCheckTimer?.cancel();
  }

  void dispose() {
    _stopTimers();
  }
}
