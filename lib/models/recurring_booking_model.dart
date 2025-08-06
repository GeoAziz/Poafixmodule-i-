class RecurringBookingModel {
  final String id;
  final String userId;
  final String userType;
  final String providerId;
  final String providerName;
  final String clientId;
  final String clientName;
  final String serviceType;
  final String serviceName;
  final Map<String, dynamic> serviceDetails;
  final RecurrencePattern recurrencePattern;
  final DateTime startDate;
  final DateTime? endDate;
  final int? maxOccurrences;
  final double amount;
  final String paymentMethod;
  final bool isActive;
  final List<RecurringBookingInstance> upcomingBookings;
  final List<RecurringBookingInstance> completedBookings;
  final Map<String, dynamic> location;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> preferences;

  RecurringBookingModel({
    required this.id,
    required this.userId,
    required this.userType,
    required this.providerId,
    required this.providerName,
    required this.clientId,
    required this.clientName,
    required this.serviceType,
    required this.serviceName,
    required this.serviceDetails,
    required this.recurrencePattern,
    required this.startDate,
    this.endDate,
    this.maxOccurrences,
    required this.amount,
    required this.paymentMethod,
    this.isActive = true,
    this.upcomingBookings = const [],
    this.completedBookings = const [],
    required this.location,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.preferences = const {},
  });

  factory RecurringBookingModel.fromJson(Map<String, dynamic> json) {
    return RecurringBookingModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      userType: json['userType'] ?? 'client',
      providerId: json['providerId'] ?? '',
      providerName: json['providerName'] ?? '',
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'] ?? '',
      serviceType: json['serviceType'] ?? '',
      serviceName: json['serviceName'] ?? '',
      serviceDetails: Map<String, dynamic>.from(json['serviceDetails'] ?? {}),
      recurrencePattern: RecurrencePattern.fromJson(json['recurrencePattern'] ?? {}),
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      maxOccurrences: json['maxOccurrences'],
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      isActive: json['isActive'] ?? true,
      upcomingBookings: (json['upcomingBookings'] as List?)
          ?.map((booking) => RecurringBookingInstance.fromJson(booking))
          .toList() ?? [],
      completedBookings: (json['completedBookings'] as List?)
          ?.map((booking) => RecurringBookingInstance.fromJson(booking))
          .toList() ?? [],
      location: Map<String, dynamic>.from(json['location'] ?? {}),
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userType': userType,
      'providerId': providerId,
      'providerName': providerName,
      'clientId': clientId,
      'clientName': clientName,
      'serviceType': serviceType,
      'serviceName': serviceName,
      'serviceDetails': serviceDetails,
      'recurrencePattern': recurrencePattern.toJson(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'isActive': isActive,
      'upcomingBookings': upcomingBookings.map((booking) => booking.toJson()).toList(),
      'completedBookings': completedBookings.map((booking) => booking.toJson()).toList(),
      'location': location,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'preferences': preferences,
    };
  }

  // Helper methods
  DateTime? get nextBookingDate {
    if (!isActive || upcomingBookings.isEmpty) return null;
    return upcomingBookings.first.scheduledDate;
  }

  int get totalBookings => upcomingBookings.length + completedBookings.length;
  double get totalAmountSpent => completedBookings.fold(0.0, (sum, booking) => sum + booking.amount);
  String get formattedAmount => 'KES ${amount.toStringAsFixed(2)}';
  
  bool get canModify => isActive && upcomingBookings.isNotEmpty;
  bool get canCancel => isActive;
}

class RecurrencePattern {
  final RecurrenceType type;
  final int interval; // Every X days/weeks/months
  final List<int> daysOfWeek; // For weekly recurrence (1=Monday, 7=Sunday)
  final int dayOfMonth; // For monthly recurrence
  final List<int> monthsOfYear; // For yearly recurrence
  final String timeOfDay; // HH:MM format
  final Map<String, dynamic> customPattern;

  RecurrencePattern({
    required this.type,
    this.interval = 1,
    this.daysOfWeek = const [],
    this.dayOfMonth = 1,
    this.monthsOfYear = const [],
    required this.timeOfDay,
    this.customPattern = const {},
  });

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) {
    return RecurrencePattern(
      type: RecurrenceType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => RecurrenceType.weekly,
      ),
      interval: json['interval'] ?? 1,
      daysOfWeek: List<int>.from(json['daysOfWeek'] ?? []),
      dayOfMonth: json['dayOfMonth'] ?? 1,
      monthsOfYear: List<int>.from(json['monthsOfYear'] ?? []),
      timeOfDay: json['timeOfDay'] ?? '09:00',
      customPattern: Map<String, dynamic>.from(json['customPattern'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'monthsOfYear': monthsOfYear,
      'timeOfDay': timeOfDay,
      'customPattern': customPattern,
    };
  }

  String get description {
    switch (type) {
      case RecurrenceType.daily:
        return interval == 1 ? 'Daily' : 'Every $interval days';
      case RecurrenceType.weekly:
        if (interval == 1) {
          if (daysOfWeek.isEmpty) return 'Weekly';
          final dayNames = daysOfWeek.map((day) => _getDayName(day)).join(', ');
          return 'Weekly on $dayNames';
        }
        return 'Every $interval weeks';
      case RecurrenceType.monthly:
        return interval == 1 ? 'Monthly' : 'Every $interval months';
      case RecurrenceType.yearly:
        return interval == 1 ? 'Yearly' : 'Every $interval years';
      case RecurrenceType.custom:
        return 'Custom pattern';
    }
  }

  String _getDayName(int dayNumber) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayNumber - 1];
  }
}

enum RecurrenceType {
  daily,
  weekly,
  monthly,
  yearly,
  custom
}

class RecurringBookingInstance {
  final String id;
  final String recurringBookingId;
  final DateTime scheduledDate;
  final String status; // 'scheduled', 'completed', 'cancelled', 'rescheduled'
  final double amount;
  final String? bookingId; // Actual booking ID when created
  final DateTime? completedDate;
  final String? cancellationReason;
  final Map<String, dynamic> customizations;

  RecurringBookingInstance({
    required this.id,
    required this.recurringBookingId,
    required this.scheduledDate,
    required this.status,
    required this.amount,
    this.bookingId,
    this.completedDate,
    this.cancellationReason,
    this.customizations = const {},
  });

  factory RecurringBookingInstance.fromJson(Map<String, dynamic> json) {
    return RecurringBookingInstance(
      id: json['id'] ?? '',
      recurringBookingId: json['recurringBookingId'] ?? '',
      scheduledDate: DateTime.parse(json['scheduledDate'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'scheduled',
      amount: (json['amount'] ?? 0).toDouble(),
      bookingId: json['bookingId'],
      completedDate: json['completedDate'] != null ? DateTime.parse(json['completedDate']) : null,
      cancellationReason: json['cancellationReason'],
      customizations: Map<String, dynamic>.from(json['customizations'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recurringBookingId': recurringBookingId,
      'scheduledDate': scheduledDate.toIso8601String(),
      'status': status,
      'amount': amount,
      'bookingId': bookingId,
      'completedDate': completedDate?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'customizations': customizations,
    };
  }

  bool get isUpcoming => status == 'scheduled' && scheduledDate.isAfter(DateTime.now());
  bool get isCompleted => status == 'completed';
  bool get canModify => status == 'scheduled' && scheduledDate.isAfter(DateTime.now().add(Duration(hours: 24)));
}