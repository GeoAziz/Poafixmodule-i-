import 'package:flutter/material.dart';
import '../../services/booking_service.dart';
import '../../models/booking.dart';
import '../service/service_tracking_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> provider;
  final DateTime scheduledTime;
  final String notes;

  const BookingConfirmationScreen({
    super.key,
    required this.provider,
    required this.scheduledTime,
    required this.notes,
  });

  @override
  _BookingConfirmationScreenState createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = false;

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    try {
      final bookingMap = await _bookingService.createBooking({
        'providerId': widget.provider['id'],
        'serviceType': widget.provider['serviceOffered'],
        'scheduledTime': widget.scheduledTime.toIso8601String(),
        'notes': widget.notes,
        'location': widget.provider['location'],
      });

      if (!mounted) return;

      // Convert the map to a Booking object
      final booking = Booking.fromJson(bookingMap);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceTrackingScreen(booking: booking),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSummaryCard(),
            const SizedBox(height: 20),
            _buildTermsAndConditions(),
            const Spacer(),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(widget.provider['name'] ?? 'Unknown Provider'),
              subtitle: Text(widget.provider['serviceOffered'] ?? 'Service'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text('Scheduled Time'),
              subtitle: Text(widget.scheduledTime.toString()),
            ),
            if (widget.notes.isNotEmpty) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.note),
                title: const Text('Notes'),
                subtitle: Text(widget.notes),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Conditions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Payment is only required after service completion'),
            Text('• You can cancel up to 1 hour before the scheduled time'),
            Text('• The provider will confirm your booking shortly'),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _confirmBooking,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.blue,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Confirm Booking',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }
}
