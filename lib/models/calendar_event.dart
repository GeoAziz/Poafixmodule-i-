import 'booking.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String type; // 'booking', 'job', 'blocked'
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String? comment;
  final Map<String, dynamic>? metadata;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    required this.status,
    this.comment,
    this.metadata,
  });

  factory CalendarEvent.fromBooking(Booking booking) {
    return CalendarEvent(
      id: booking.id,
      title: booking.displayServiceName,
      description: 'Client: ${booking.displayClientName}',
      date: booking.scheduledDate,
      type: 'booking',
      status: booking.status,
      comment: booking.displayNotes,
      metadata: {
        'clientId': booking.client,
        'providerId': booking.provider,
        'amount': booking.amount,
      },
    );
  }
}
