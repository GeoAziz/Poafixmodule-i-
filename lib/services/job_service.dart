import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/job.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/auth_service.dart';

class JobService {
  static final JobService _instance = JobService._internal();
  static final _storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  factory JobService() => _instance;
  JobService._internal();

  final _jobsController = StreamController<List<Job>>.broadcast();
  Stream<List<Job>> get jobsStream => _jobsController.stream;

  WebSocketChannel? _channel;

  Future<void> connectToWebSocket() async {
    final token = await _storage.read(key: 'auth_token');
    final wsUrl = Uri.parse('ws://${ApiConfig.baseUrl.split('//')[1]}/ws');

    _channel = WebSocketChannel.connect(wsUrl);
    _channel!.sink.add(json.encode({'type': 'auth', 'token': token}));

    _channel!.stream.listen(
      (message) {
        final data = json.decode(message);
        if (data['type'] == 'job_update') {
          updateJobs(); // Refresh jobs when update received
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        reconnectWebSocket();
      },
      onDone: () {
        print('WebSocket connection closed');
        reconnectWebSocket();
      },
    );
  }

  Future<void> reconnectWebSocket() async {
    await Future.delayed(Duration(seconds: 5));
    connectToWebSocket();
  }

  Future<void> updateJobs() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/jobs'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jobsData = json.decode(response.body);
        final jobs = jobsData.map((job) => Job.fromJson(job)).toList();
        _jobsController.add(jobs);
      } else {
        throw Exception('Failed to load jobs');
      }
    } catch (e) {
      print('Error updating jobs: $e');
      _jobsController.addError(e);
    }
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/jobs/$jobId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': status}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update job status');
      }

      await updateJobs(); // Refresh jobs after update
    } catch (e) {
      print('Error updating job status: $e');
      throw Exception('Failed to update job status: $e');
    }
  }

  Future<Map<String, dynamic>> createBooking(
      Map<String, dynamic> bookingData) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bookingData),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Failed to create booking'
        };
      }
    } catch (e) {
      print('Error creating booking: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<Job>> getProviderJobs() async {
    try {
  final token = await _storage.read(key: 'auth_token');
      final providerId = await _storage.read(key: 'userId');

      if (token == null || providerId == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/jobs/provider/$providerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List).map((job) => Job.fromJson(job)).toList();
      }

      throw Exception('Failed to fetch jobs');
    } catch (e) {
      print('Error fetching jobs: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateBookingStatus({
    required String bookingId,
    required String status,
    required String providerId,
  }) async {
    try {
      // First try to get token from storage directly
  final token = await _storage.read(key: 'auth_token') ??
          await _storage.read(key: 'auth_token');

      // If still null, try auth service
      if (token == null) {
        final authToken = await _authService.getToken();
        if (authToken == null) {
          throw Exception('Authentication token not found');
        }
      }

      print('Debug - Token found: ${token != null}');

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/bookings/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': status,
          'providerId': providerId,
        }),
      );

      print('Debug - Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update booking status: ${response.statusCode}');
      }

      return json.decode(response.body);
    } catch (e) {
      print('Error updating booking status: $e');
      throw Exception('Error updating booking status: $e');
    }
  }

  void dispose() {
    _channel?.sink.close();
    _jobsController.close();
  }
}
