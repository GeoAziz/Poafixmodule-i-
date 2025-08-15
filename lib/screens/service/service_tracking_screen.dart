import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking.dart';
import '../payment/mpesa_payment_screen.dart';
import '../../providers/booking_notifier.dart';

class ServiceTrackingScreen extends StatefulWidget {
  final Booking booking;

  const ServiceTrackingScreen({super.key, required this.booking});

  @override
  _ServiceTrackingScreenState createState() => _ServiceTrackingScreenState();
}

class _ServiceTrackingScreenState extends State<ServiceTrackingScreen> {
  late BookingNotifier _bookingNotifier;

  @override
  void initState() {
    super.initState();
    _bookingNotifier = BookingNotifier();
    _bookingNotifier.initialize(widget.booking);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _bookingNotifier,
      child: Scaffold(
        appBar: AppBar(title: const Text('Service Progress')),
        body: Consumer<BookingNotifier>(
          builder: (context, notifier, child) {
            final booking = notifier.currentBooking;
            if (booking == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _buildStatusTimeline(_parseBookingStatus(booking.status)),
                _buildServiceDetails(booking),
                if (booking.status == BookingStatus.completed)
                  _buildPaymentButton(booking),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(BookingStatus status) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: BookingStatus.values.map((status) {
          final isCompleted = status.index <= status.index;
          return ListTile(
            leading: Icon(
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: isCompleted ? Colors.green : Colors.grey,
            ),
            title: Text(status.toString().split('.').last),
            subtitle: Text(_getStatusDescription(status)),
          );
        }).toList(),
      ),
    );
  }

  String _getStatusDescription(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Waiting for provider confirmation';
      case BookingStatus.accepted:
        return 'Service provider has accepted';
      case BookingStatus.in_progress:
        return 'Service is being performed';
      case BookingStatus.completed:
        return 'Service completed, payment pending';
      default:
        return '';
    }
  }

  Widget _buildServiceDetails(Booking booking) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${booking.serviceType}'),
            Text('Time: ${booking.scheduledTime}'),
            Text('Notes: ${booking.notes}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton(Booking booking) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MpesaPaymentScreen(booking: booking),
          ),
        ),
        child: const Text('Proceed to Payment'),
      ),
    );
  }

  BookingStatus _parseBookingStatus(String status) {
    return BookingStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => BookingStatus.pending,
    );
  }

  @override
  void dispose() {
    _bookingNotifier.dispose();
    super.dispose();
  }
}
