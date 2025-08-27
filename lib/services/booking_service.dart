import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../models/booking.dart';
import '../config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../config/db_config.dart';
import '../services/auth_storage.dart';
import '../services/websocket_service.dart';
import '../services/auth_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:dio/dio.dart';

class BookingService {
  // Always use ApiConfig.baseUrl dynamically for every request
  final _storage = FlutterSecureStorage();
  Db? _db;
  DbCollection? _bookings;
  bool _isInitialized = false;

  // Add debug logging for all API calls
  Future<List<Booking>> fetchClientBookings(String clientId) async {
    final url = ApiConfig.getEndpointUrl('bookings/client/$clientId');
    print('[BookingService] GET $url');
    try {
      final response = await Dio().get(url);
      print(
        '[BookingService] Response: ${response.statusCode} ${response.data}',
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is String
            ? json.decode(response.data)
            : response.data;
        return data.map((e) => Booking.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      print('[BookingService] Error: $e');
      rethrow;
    }
  }

  final AuthStorage _authStorage = AuthStorage();
  final AuthService _authService = AuthService();

  // Add Dio instance
  // Remove cached Dio instance. Use Dio() directly in each request.

  // Add these fields
  final _webSocketService = WebSocketService();
  final _bookingUpdateController = StreamController<List<Booking>>.broadcast();

  Stream<List<Booking>> get bookingUpdates => _bookingUpdateController.stream;

  final _pendingActionsQueue = <Map<String, dynamic>>[];
  bool _isProcessingQueue = false;

  // Remove factory constructor and singleton pattern. Use default constructor only.

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    int retryCount = 0;
    while (retryCount < DbConfig.maxRetries) {
      try {
        print('Attempting MongoDB connection (attempt ${retryCount + 1})...');
        _db = await Db.create(DbConfig.mongoUrl);
        await _db?.open();
        _bookings = _db?.collection('bookings');
        _isInitialized = true;
        print('MongoDB connected successfully');
        return;
      } catch (e) {
        retryCount++;
        print('MongoDB connection error (attempt $retryCount): $e');

        if (retryCount < DbConfig.maxRetries) {
          await Future.delayed(Duration(seconds: 1)); // Wait before retrying
          continue;
        }

        // Try fallback connection on last attempt
        if (retryCount == DbConfig.maxRetries) {
          await _tryFallbackConnection();
        }
      }
    }
  }

  Future<void> _tryFallbackConnection() async {
    final List<String> connectionUrls = [
      'mongodb://10.0.2.2:27017/home_service_db?directConnection=true',
      'mongodb://127.0.0.1:27017/home_service_db?directConnection=true',
      'mongodb://localhost:27017/home_service_db?directConnection=true',
    ];

    for (final url in connectionUrls) {
      try {
        print('Attempting MongoDB connection with URL: $url');
        _db = await Db.create(url);
        await _db?.open();

        // Verify connection
        final serverStatus = await _db?.serverStatus();
        print('MongoDB server status: $serverStatus');

        _bookings = _db?.collection('bookings');

        // Test collection access
        final count = await _bookings?.count();
        print('Bookings collection count: $count');

        _isInitialized = true;
        print('Successfully connected to MongoDB using: $url');
        return;
      } catch (e) {
        print('Connection failed for $url: ${e.toString()}');
        await _db?.close();
        continue;
      }
    }
    throw Exception('Could not connect to MongoDB using any available URLs');
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<Map<String, dynamic>> createBooking(
    Map<String, dynamic> bookingData,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      // Convert date and time to UTC format that server expects
      final scheduledDate = DateTime.parse(bookingData['scheduledDate']);
      final scheduledTime = bookingData['scheduledTime'];
      final timeParts = scheduledTime.toString().split(' ')[0].split(':');
      final isPM = scheduledTime.toString().contains('PM');
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (isPM && hour < 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0;
      }

      final schedule = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        hour,
        minute,
      ).toUtc();

      // Format the data according to server requirements
      final requestData = {
        'providerId': bookingData['providerId'],
        'clientId': bookingData['clientId'],
        'serviceType': bookingData['serviceType'],
        'schedule': schedule.toIso8601String(),
        'description': bookingData['notes'] ?? '',
        'address': bookingData['location']['address'] ?? '',
        'status': 'pending',
        'location': {
          'type': 'Point',
          'coordinates': bookingData['location']['coordinates'],
        },
      };

      print('Formatted booking request: ${json.encode(requestData)}');

      final response = await http
          .post(
            Uri.parse(ApiConfig.getEndpointUrl('bookings')),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      print('Booking response status: ${response.statusCode}');
      print('Booking response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final bookingResponse = responseData['data'];

          // Send notification to provider
          await _sendProviderNotification(
            bookingData['providerId'],
            bookingData['serviceType'],
            bookingResponse['_id'],
          );

          // Emit booking created event
          _webSocketService.socket.emit('booking_created', {
            'bookingId': bookingResponse['_id'],
            'providerId': bookingResponse['providerId'],
            'timestamp': bookingResponse['createdAt'],
          });

          return {'success': true, 'booking': bookingResponse};
        }
      }

      throw Exception(
        'Server returned ${response.statusCode}: ${response.body}',
      );
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  Future<void> _sendProviderNotification(
    String providerId,
    String serviceType,
    String bookingId,
  ) async {
    // FIX: Use correct keys and type
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return;

    final response = await http.post(
      Uri.parse(ApiConfig.getEndpointUrl('notifications')),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'recipient': providerId, // FIX: use 'recipient'
        'recipientModel': 'provider', // FIX: use 'provider'
        'type': 'BOOKING_REQUEST', // FIX: use correct type
        'title': 'New Booking Request',
        'message': 'You have a new $serviceType service request',
        'bookingId': bookingId,
        'createdAt': DateTime.now().toIso8601String(),
        'data': {'bookingId': bookingId, 'serviceType': serviceType},
      }),
    );

    print('Notification response: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> acceptBooking(String bookingId) async {
    try {
      final result = await _makeRequest(
        'POST',
        '/bookings/$bookingId/accept',
        retryCount: 3,
      );
      return result;
    } catch (e) {
      if (e is Exception && e.toString().contains('network')) {
        // Save for offline processing
        await _savePendingAction({
          'type': 'accept',
          'bookingId': bookingId,
          'timestamp': DateTime.now().toIso8601String(),
        });
        throw Exception(
          'No network connection. Action will be processed when online.',
        );
      }
      rethrow;
    }
  }

  Future<void> rejectBooking(String bookingId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final userId = await _storage.read(key: 'userId');

      if (token == null || userId == null) {
        throw Exception('Authentication required');
      }

      print('📝 Rejecting booking: $bookingId');
      print('🔑 Provider ID: $userId');

      final response = await http.patch(
        Uri.parse(ApiConfig.getEndpointUrl('bookings/$bookingId')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'User-Type': 'service-provider',
        },
        body: json.encode({
          'status': 'rejected', // Changed to lowercase
          'providerId': userId,
        }),
      );

      print('📤 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to reject booking');
      }

      // Emit WebSocket event
      _webSocketService.socket.emit('booking_status_update', {
        'bookingId': bookingId,
        'status': 'rejected',
        'providerId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error rejecting booking: $e');
      rethrow;
    }
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    final response = await http.patch(
      Uri.parse(ApiConfig.getEndpointUrl('bookings/$bookingId/status')),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status.toString().split('.').last}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update booking status: ${response.body}');
    }
  }

  Future<List<Booking>> getClientBookings(String clientId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final userType = await _storage.read(key: 'userType');

      if (token == null) throw Exception('No auth token found');

      print('Fetching bookings for client: $clientId');
      print('Token: ${token.substring(0, 10)}...'); // Debug token

      final dio = Dio();
      final response = await dio.get(
        '${ApiConfig.baseUrl}/api/bookings/client/$clientId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'user-type': userType ?? 'client', // Add user-type header
          },
          validateStatus: (status) => status! < 500, // Allow 4xx responses
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> bookingsData = response.data['data'];
        return bookingsData
            .map((booking) => Booking.fromJson(booking))
            .toList();
      }

      throw Exception('Failed to fetch bookings: ${response.statusCode}');
    } on DioException catch (e) {
      print('DioError in getClientBookings:');
      print('URL: ${e.requestOptions.uri}');
      print('Headers: ${e.requestOptions.headers}');
      print('Response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('General error in getClientBookings: $e');
      rethrow;
    }
  }

  Future<List<Booking>> getProviderBookings() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final providerId = await _storage.read(key: 'userId');

      if (token == null || providerId == null) {
        throw Exception('Authentication data missing');
      }

      print('🔐 Fetching provider bookings...');
      print('Provider ID: $providerId');
      print('Token: ${token.substring(0, 10)}...');

      final response = await http.get(
        Uri.parse(ApiConfig.getEndpointUrl('bookings/provider/$providerId')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> bookingsData = responseData['data'];
          return bookingsData
              .map((booking) {
                try {
                  // Clean up the booking data before parsing
                  if (booking['_doc'] != null) {
                    booking = booking['_doc'];
                  }
                  return Booking.fromJson(booking);
                } catch (e) {
                  print('Error parsing booking: $e');
                  return null;
                }
              })
              .where((booking) => booking != null)
              .cast<Booking>()
              .toList();
        }

        throw Exception('Invalid response format');
      }

      throw Exception('Failed to fetch bookings: ${response.statusCode}');
    } catch (e) {
      print('❌ Error in getProviderBookings: $e');
      rethrow;
    }
  }

  String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) return value['_id'] ?? value['id'];
    return null;
  }

  Stream<List<Booking>> getUserBookings(String userId) async* {
    await ensureInitialized();

    if (_bookings == null) throw Exception('BookingService not initialized');

    try {
      await for (var data in _bookings!.find(where.eq('clientId', userId))) {
        // Change fromMap to fromJson since we only have fromJson in our Booking model
        yield [Booking.fromJson(data)];
      }
    } catch (e) {
      print('Error getting user bookings: $e');
      throw Exception('Failed to get user bookings: $e');
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final userId = await _storage.read(key: 'userId');

      if (token == null || userId == null) {
        throw Exception('Authentication credentials missing');
      }

      print('Attempting to cancel booking: $bookingId');

      // Changed endpoint structure to match backend
      final response = await http.patch(
        Uri.parse(ApiConfig.getEndpointUrl('bookings/$bookingId/cancel')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Type': 'client', // Added user type
        },
        body: jsonEncode({'userId': userId, 'status': 'cancelled'}),
      );

      print('Cancel booking response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 404) {
        throw Exception('Booking not found');
      }

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'Failed to cancel booking');
      }

      // Emit websocket event only on success
      _webSocketService.socket.emit('booking_status_updated', {
        'bookingId': bookingId,
        'status': 'cancelled',
        'userId': userId,
      });
    } catch (e) {
      print('Error canceling booking: $e');
      rethrow;
    }
  }

  // Add method to get current user ID
  Future<String> _getCurrentUserId() async {
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) throw Exception('User ID not found');
    return userId;
  }

  Future<void> _savePendingAction(Map<String, dynamic> action) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/pending_actions.json');

    List<Map<String, dynamic>> actions = [];
    if (await file.exists()) {
      final content = await file.readAsString();
      actions = List<Map<String, dynamic>>.from(json.decode(content));
    }

    actions.add(action);
    await file.writeAsString(json.encode(actions));
    _pendingActionsQueue.add(action);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue || _pendingActionsQueue.isEmpty) return;

    _isProcessingQueue = true;

    try {
      while (_pendingActionsQueue.isNotEmpty) {
        final action = _pendingActionsQueue.first;

        switch (action['type']) {
          case 'accept':
            await acceptBooking(action['bookingId']);
            break;
          case 'reject':
            await rejectBooking(action['bookingId']);
            break;
          // Add other action types as needed
        }

        _pendingActionsQueue.removeAt(0);
        await _updatePendingActionsFile();
      }
    } catch (e) {
      print('Error processing queue: $e');
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<void> _updatePendingActionsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/pending_actions.json');
    await file.writeAsString(json.encode(_pendingActionsQueue));
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) throw Exception('No authentication token found');

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    int retryCount = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    Exception? lastError;

    for (var i = 0; i < retryCount; i++) {
      try {
        final response = await http
            .post(
              Uri.parse(ApiConfig.getEndpointUrl(endpoint)),
              headers: await _getHeaders(),
              body: body != null ? json.encode(body) : null,
            )
            .timeout(Duration(seconds: 30));

        print('📡 API Request: $method $endpoint');
        print('📡 Response Status: ${response.statusCode}');
        print('📡 Response Body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          return json.decode(response.body);
        }

        throw Exception('Request failed with status: ${response.statusCode}');
      } catch (e) {
        print('❌ Request attempt ${i + 1} failed: $e');
        lastError = e as Exception;

        if (i < retryCount - 1) {
          await Future.delayed(retryDelay * (i + 1));
          continue;
        }
      }
    }

    throw lastError ?? Exception('Request failed after $retryCount attempts');
  }

  void dispose() async {
    if (_isInitialized) {
      await _db?.close();
      _db = null;
      _bookings = null;
      _isInitialized = false;
    }
    _bookingUpdateController.close();
  }
}
