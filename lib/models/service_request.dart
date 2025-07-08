class ServiceRequest {
  final String id;
  final String clientId;
  final String providerId;
  final String serviceType;
  final String status;
  final DateTime initialRequestTime;
  final DateTime? providerResponseTime;
  final String responseStatus;
  final String? rejectionReason;
  final DateTime scheduledDate;
  final Map<String, dynamic> location;
  final double amount;
  final String? notes;
  final DateTime? completedAt;
  final DateTime createdAt;

  ServiceRequest({
    required this.id,
    required this.clientId,
    required this.providerId,
    required this.serviceType,
    required this.status,
    required this.initialRequestTime,
    this.providerResponseTime,
    required this.responseStatus,
    this.rejectionReason,
    required this.scheduledDate,
    required this.location,
    required this.amount,
    this.notes,
    this.completedAt,
    required this.createdAt,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          '', // Handle null and convert to String
      clientId: json['clientId']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      serviceType: json['serviceType']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      initialRequestTime: DateTime.parse(
          json['createdAt']), // Use createdAt if initialRequestTime is missing
      providerResponseTime: json['providerResponseTime'] != null
          ? DateTime.parse(json['providerResponseTime'])
          : null,
      responseStatus: json['responseStatus']?.toString() ?? 'pending',
      rejectionReason: json['rejectionReason']?.toString(),
      scheduledDate: DateTime.parse(json['scheduledDate']),
      location: json['location'] ??
          {
            'type': 'Point',
            'coordinates': [0, 0]
          },
      amount: (json['amount'] ?? 0).toDouble(),
      notes: json['notes']?.toString(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
