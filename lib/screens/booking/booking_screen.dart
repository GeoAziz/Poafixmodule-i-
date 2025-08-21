import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import '../../services/booking_service.dart';
import '../bookings/bookings_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/http_service.dart';
import '../../services/job_service.dart';
import '../../services/service_request.service.dart';
import '../payment/service_payment_screen.dart';
import '../home/home_screen.dart';
import '../../models/user_model.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic>? provider;
  final String? serviceOffered;
  final String? providerName;
  final String? providerId;
  final String? clientId;
  final List<Map<String, dynamic>>? selectedServices;
  // New parameters for service selection screen
  final User? user;
  final String? selectedService;

  const BookingScreen({
    super.key,
    this.provider,
    this.serviceOffered,
    this.providerName,
    this.providerId,
    this.clientId,
    this.selectedServices,
    this.user,
    this.selectedService,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final noteController = TextEditingController();
  bool _isLoading = false;
  final _storage = const FlutterSecureStorage();
  final HttpService _httpService = HttpService();
  final _jobService = JobService();
  // Default coordinates (you might want to get these from device location)
  double latitude = 0.0;
  double longitude = 0.0;

  // Add clientId field
  String? _effectiveClientId;
  // Track if clientId is loaded and valid
  bool get _isClientIdReady =>
      _effectiveClientId != null && _effectiveClientId!.isNotEmpty;

  // Always load clientId from secure storage before booking submission
  Future<void> _ensureClientIdLoaded() async {
    if (_effectiveClientId == null || _effectiveClientId!.isEmpty) {
      final clientId = await _storage.read(key: 'userId');
      print(
        '[DEBUG] _ensureClientIdLoaded: Read clientId from storage: $clientId',
      );
      if (clientId != null && clientId.isNotEmpty) {
        setState(() {
          _effectiveClientId = clientId;
        });
        print('[DEBUG] Loaded client ID (on demand): $_effectiveClientId');
      } else {
        print('[DEBUG] No client ID found in storage (on demand)');
        _showErrorDialog('Client ID not found. Please login again.');
      }
    } else {
      print(
        '[DEBUG] _ensureClientIdLoaded: _effectiveClientId already set: $_effectiveClientId',
      );
    }
  }

  final BookingService _bookingService = BookingService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadClientId(); // Add this
    _logSelectedServices(); // Add debug logging
  }

  Future<void> _initializeServices() async {
    try {
      await _bookingService.initialize();
      await _loadClientId();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Initialization error: $e');
      _showErrorDialog('Failed to initialize services: $e');
    }
  }

  // Add method to load client ID
  Future<void> _loadClientId() async {
    try {
      final storage = const FlutterSecureStorage();
      final clientId = await storage.read(key: 'userId');
      print('[DEBUG] _loadClientId: Read clientId from storage: $clientId');
      if (clientId != null && clientId.isNotEmpty) {
        setState(() {
          _effectiveClientId = clientId;
        });
        print('[DEBUG] Loaded client ID: $_effectiveClientId');
      } else {
        print('[DEBUG] No client ID found in storage');
        _showErrorDialog('Client ID not found. Please login again.');
      }
    } catch (e) {
      print('[DEBUG] Error loading client ID: $e');
      _showErrorDialog('Error loading client information');
    }
  }

  void _logSelectedServices() {
    print('Selected services in booking screen:');
    print('Number of services: ${widget.selectedServices?.length ?? 0}');
    widget.selectedServices?.forEach((service) {
      print(
        'Service: ${service['name']}, Quantity: ${service['quantity']}, Price: ${service['basePrice']}',
      );
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    print('🔄 Starting booking submission...');
    await _ensureClientIdLoaded();
    print(
      '[DEBUG] _submitBooking: _effectiveClientId after ensure: $_effectiveClientId',
    );
    if (!_isClientIdReady) {
      print(
        '[DEBUG] _submitBooking: clientId not ready, aborting booking submission',
      );
      _showErrorDialog('Client ID not loaded. Please login again.');
      return;
    }
    if (!_validateBooking()) {
      print('❌ Validation failed, stopping submission');
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Calculate services with proper validation
      final services = (widget.selectedServices ?? []).map((service) {
        final quantity = (service['quantity'] as int?) ?? 1;
        final basePrice = (service['basePrice'] as num?)?.toDouble() ?? 0.0;

        print('📦 Processing service:');
        print('Name: ${service['name']}');
        print('Quantity: $quantity');
        print('Base Price: $basePrice');

        return {
          'name': service['name'],
          'quantity': quantity < 1 ? 1 : quantity,
          'basePrice': basePrice,
          'totalPrice': (quantity < 1 ? 1 : quantity) * basePrice,
        };
      }).toList();

      final totalAmount = services.fold<double>(
        0.0,
        (sum, service) => sum + (service['totalPrice'] as double),
      );

      print('💰 Total amount calculated: $totalAmount');

      // Create service request
      if (_effectiveClientId == null) {
        throw Exception('Client ID is required');
      }
      final serviceRequest = await ServiceRequestService().createRequest(
        providerId: widget.providerId ?? '',
        clientId: _effectiveClientId!, // Add non-null assertion
        serviceType: widget.serviceOffered ?? '',
        scheduledDate: DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          selectedTime!.hour,
          selectedTime!.minute,
        ),
        location: {
          'coordinates':
              (widget.provider?['location']?['coordinates']) ??
              [36.8337083, -1.3095883],
          'type': 'Point',
        },
        amount: totalAmount,
        notes: noteController.text,
      );

      print('📝 Service request created with ID: ${serviceRequest['id']}');

      // Create booking with the service request ID
      final bookingData = {
        'providerId': widget.providerId ?? '',
        'clientId': _effectiveClientId,
        'serviceType': widget.serviceOffered ?? '',
        'serviceName':
            (widget.selectedServices != null &&
                widget.selectedServices!.isNotEmpty)
            ? widget.selectedServices!.first['name']
            : '',
        'scheduledDate': selectedDate!.toIso8601String(),
        'scheduledTime': selectedTime!.format(context),
        'notes': noteController.text,
        'amount': totalAmount,
        'services': services,
        'status': 'pending',
        'payment': {'method': 'mpesa', 'status': 'pending'},
        'location': {
          'coordinates':
              (widget.provider?['location']?['coordinates']) ??
              [36.8337083, -1.3095883],
          'type': 'Point',
        },
        'serviceRequestId': serviceRequest['id'],
      };

      print('📤 Submitting booking data...');
      final response = await _bookingService.createBooking(bookingData);

      if (!mounted) return;

      if (response['success'] == true && response['booking'] != null) {
        print('✅ Booking created successfully');
        _showBookingSuccessDialog();
      } else {
        throw Exception('Booking creation failed: ${response['error']}');
      }
    } catch (e) {
      print('❌ Error in _submitBooking: $e');
      if (mounted) {
        _showErrorDialog('Failed to create booking: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateBooking() {
    print('🔍 Starting booking validation...');

    // Basic validations
    if (selectedDate == null) {
      _showErrorDialog('Please select a date');
      return false;
    }

    if (selectedTime == null) {
      _showErrorDialog('Please select a time');
      return false;
    }

    if (_effectiveClientId == null || _effectiveClientId!.isEmpty) {
      _showErrorDialog('Client ID not found. Please login again');
      return false;
    }

    if ((widget.providerId?.isEmpty ?? true)) {
      _showErrorDialog('Provider information missing');
      return false;
    }

    if ((widget.selectedServices?.isEmpty ?? true)) {
      _showErrorDialog('Please select at least one service');
      return false;
    }

    // Skip quantity validation for moving service
    if ((widget.serviceOffered?.toLowerCase() ?? '') != 'moving') {
      // Only validate quantities for non-moving services
      for (final service in widget.selectedServices ?? []) {
        final quantity = service['quantity'] as int?;
        if (quantity == null || quantity < 1) {
          _showErrorDialog(
            'Please select a valid quantity for ${service['name']}',
          );
          return false;
        }
      }
    }

    print('✅ Validation successful');
    return true;
  }

  Future<void> _completeService(String bookingId) async {
    try {
      final response = await _httpService.authenticatedRequest(
        '/api/bookings/$bookingId/complete',
        method: 'PATCH',
        body: {'serviceStatus': 'completed'},
      );

      if (response.statusCode == 200) {
        // Navigate to payment screen
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServicePaymentScreen(
              booking: json.decode(response.body),
              amount: (widget.selectedServices ?? []).fold<double>(
                0,
                (sum, service) =>
                    sum +
                    ((service['basePrice'] ?? 0.0) *
                        (service['quantity'] ?? 1)),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _notifyProvider(Map<String, dynamic> bookingData) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'type': 'NEW_BOOKING',
          'recipientId': widget.providerId, // Send as string
          'title': 'New Booking Request',
          'message':
              'You have a new booking request for ${widget.serviceOffered}',
          'data': bookingData,
        }),
      );
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  void _handleSessionExpired() {
    Navigator.of(context).pushReplacementNamed('/login');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session expired. Please login again.')),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Your booking has been submitted successfully!'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                final storage = FlutterSecureStorage();
                final userId = await storage.read(key: 'userId');
                final name = await storage.read(key: 'name');
                final email = await storage.read(key: 'email');
                final userType = await storage.read(key: 'userType');
                final phone = await storage.read(key: 'phone');
                final token = await storage.read(key: 'auth_token');

                Navigator.of(context).pop(); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingsScreen(
                      user: User(
                        id: userId ?? '',
                        name: name ?? '',
                        email: email ?? '',
                        userType: userType ?? 'client',
                        phone: phone ?? '',
                        token: token,
                        avatarUrl: '',
                      ),
                      showNavigation: true,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showBookingSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Booking Successful!'),
        content: Text('Your booking has been created successfully.'),
        actions: [
          TextButton(
            child: Text('View Bookings'),
            onPressed: () async {
              final storage = FlutterSecureStorage();
              final userId = await storage.read(key: 'userId');
              final name = await storage.read(key: 'name');
              final email = await storage.read(key: 'email');
              final userType = await storage.read(key: 'userType');
              final phone = await storage.read(key: 'phone');
              final token = await storage.read(key: 'auth_token');

              // Close dialog first
              Navigator.pop(context);
              // Use direct navigation instead of named route
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingsScreen(
                    user: User(
                      id: userId ?? '',
                      name: name ?? '',
                      email: email ?? '',
                      userType: userType ?? 'client',
                      phone: phone ?? '',
                      token: token,
                      avatarUrl: '',
                    ),
                    showNavigation: true, // Pass the parameter
                  ),
                ),
                (route) => false,
              );
            },
          ),
          TextButton(
            child: Text('Go Home'),
            onPressed: () async {
              final storage = FlutterSecureStorage();
              final userId = await storage.read(key: 'userId');
              final name = await storage.read(key: 'name');
              final email = await storage.read(key: 'email');
              final userType = await storage.read(key: 'userType');
              final phone = await storage.read(key: 'phone');
              final token = await storage.read(key: 'auth_token');

              // Close dialog first
              Navigator.pop(context);

              // Use direct navigation instead of named route
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    user: User(
                      id: userId ?? '',
                      name: name ?? '',
                      email: email ?? '',
                      userType: userType ?? 'client',
                      phone: phone ?? '',
                      token: token,
                      avatarUrl: '',
                    ),
                  ),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(children: [Text(message)]),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(widget.providerName ?? ''),
                subtitle: Text(widget.serviceOffered ?? ''),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                selectedDate == null
                    ? 'Select Date'
                    : 'Date: ${selectedDate!.toLocal().toString().split(' ')[0]}',
              ),
              onTap: () => _selectDate(context),
              tileColor: selectedDate == null
                  ? Colors.grey[200]
                  : Colors.green[100],
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                selectedTime == null
                    ? 'Select Time'
                    : 'Time: ${selectedTime!.format(context)}',
              ),
              onTap: () => _selectTime(context),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _isClientIdReady ? _submitBooking : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isClientIdReady
                            ? Colors.green
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                      ),
                      child: Text(
                        _isClientIdReady
                            ? 'Confirm Booking'
                            : 'Loading Client Info...',
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }
}
