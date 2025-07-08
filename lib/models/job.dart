import 'package:intl/intl.dart';

class Job {
  final String id;
  final String bookingId;
  final String providerId;
  final String clientId;
  final String status;
  final String serviceType;
  final DateTime scheduledDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final Map<String, dynamic> location;
  final double amount;
  final Map<String, dynamic> payment;
  final String? notes;
  final String? completionNotes;
  final Map<String, dynamic>? rating;
  final Map<String, dynamic>? client;
  final String? description;

  Job({
    required this.id,
    required this.bookingId,
    required this.providerId,
    required this.clientId,
    required this.status,
    required this.serviceType,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    required this.location,
    required this.amount,
    required this.payment,
    this.notes,
    this.completionNotes,
    this.rating,
    this.client,
    this.description,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['_id'],
      bookingId: json['bookingId'],
      providerId: json['providerId'],
      clientId: json['clientId'],
      status: json['status'],
      serviceType: json['serviceType'],
      scheduledDate: DateTime.parse(json['scheduledDate']),
      startTime:
          json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      location: json['location'],
      amount: (json['amount'] ?? 0).toDouble(),
      payment: json['payment'],
      notes: json['notes'],
      completionNotes: json['completionNotes'],
      rating: json['rating'],
      client: json['client'],
      description: json['description'],
    );
  }

  String get clientName {
    // Format client ID for display
    return 'Client #${clientId.substring(0, 6)}';
  }

  String get scheduledTime {
    // Use startTime if available, otherwise format scheduledDate
    if (startTime != null) {
      return DateFormat('HH:mm').format(startTime!);
    }
    return DateFormat('HH:mm').format(scheduledDate);
  }

  String get displayServiceType =>
      serviceType.replaceAll('_', ' ').toLowerCase();
  String get displayDate => DateFormat('MMM d, y').format(scheduledDate);
  String get displayAmount => '\$${amount.toStringAsFixed(2)}';
  String get displayStatus => status.toUpperCase();
  String get displayLocation =>
      location['address']?.toString() ?? 'No address provided';
  String get displayNotes => notes ?? 'No notes';
}
