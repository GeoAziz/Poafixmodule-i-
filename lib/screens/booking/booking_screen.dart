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
  String? _effectiveClientId;
  final _storage = const FlutterSecureStorage();
  final BookingService _bookingService = BookingService();

  bool get _isClientIdReady =>
      _effectiveClientId != null && _effectiveClientId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _ensureClientIdLoaded();
  }

  Future<void> _ensureClientIdLoaded() async {
    final clientId = await _storage.read(key: 'userId');
    if (clientId != null && clientId.isNotEmpty) {
      setState(() {
        _effectiveClientId = clientId;
      });
    }
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
    if (!_isClientIdReady) {
      _showErrorDialog('Client ID not loaded. Please login again.');
      return;
    }
    if (!_validateBooking()) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final services = (widget.selectedServices ?? []).map((service) {
        final quantity = (service['quantity'] as int?) ?? 1;
        final basePrice = (service['basePrice'] as num?)?.toDouble() ?? 0.0;
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
      final serviceRequest = await ServiceRequestService().createRequest(
        providerId: widget.providerId ?? '',
        clientId: _effectiveClientId!,
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
      final response = await _bookingService.createBooking(bookingData);
      if (!mounted) return;
      if (response['success'] == true && response['booking'] != null) {
        _showBookingSuccessDialog();
      } else {
        throw Exception('Booking creation failed: ${response['error']}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to create booking: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateBooking() {
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
    if ((widget.serviceOffered?.toLowerCase() ?? '') != 'moving') {
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
    return true;
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
              Navigator.of(context, rootNavigator: true).pop();
              final user = User(
                id: userId ?? '',
                name: name ?? '',
                email: email ?? '',
                userType: userType ?? 'client',
                phone: phone ?? '',
                token: token,
                avatarUrl: '',
              );
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      BookingsScreen(user: user, showNavigation: true),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        final slideTween = Tween<Offset>(
                          begin: Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOut));
                        final fadeTween = Tween<double>(
                          begin: 0.0,
                          end: 1.0,
                        ).chain(CurveTween(curve: Curves.easeIn));
                        return SlideTransition(
                          position: animation.drive(slideTween),
                          child: FadeTransition(
                            opacity: animation.drive(fadeTween),
                            child: child,
                          ),
                        );
                      },
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
              Navigator.of(context, rootNavigator: true).pop();
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
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
      barrierDismissible: false,
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
