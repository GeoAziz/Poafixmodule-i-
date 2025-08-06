class Review {
  final String id;
  final String bookingId;
  final String providerId;
  final String clientId;
  final String clientName;
  final double rating;
  final String review;
  final DateTime date;
  final String serviceType;
  final List<String> images;
  final bool isVerified;
  final int likes;
  final bool isLikedByUser;
  final String? providerResponse;
  final DateTime? responseDate;

  Review({
    required this.id,
    required this.bookingId,
    required this.providerId,
    required this.clientId,
    required this.clientName,
    required this.rating,
    required this.review,
    required this.date,
    required this.serviceType,
    this.images = const [],
    this.isVerified = false,
    this.likes = 0,
    this.isLikedByUser = false,
    this.providerResponse,
    this.responseDate,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      providerId: json['providerId'] ?? '',
      clientId: json['clientId']?['_id'] ?? json['clientId'] ?? '',
      clientName: json['clientId']?['name'] ?? json['clientName'] ?? 'Anonymous',
      rating: (json['rating'] ?? 0).toDouble(),
      review: json['review'] ?? '',
      date: DateTime.parse(json['date'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      serviceType: json['serviceType'] ?? '',
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      isVerified: json['isVerified'] ?? false,
      likes: json['likes'] ?? 0,
      isLikedByUser: json['isLikedByUser'] ?? false,
      providerResponse: json['providerResponse'],
      responseDate: json['responseDate'] != null ? DateTime.parse(json['responseDate']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'bookingId': bookingId,
        'providerId': providerId,
        'clientId': clientId,
        'rating': rating,
        'review': review,
        'serviceType': serviceType,
        'images': images,
      };

  Review copyWith({
    String? id,
    String? bookingId,
    String? providerId,
    String? clientId,
    String? clientName,
    double? rating,
    String? review,
    DateTime? date,
    String? serviceType,
    List<String>? images,
    bool? isVerified,
    int? likes,
    bool? isLikedByUser,
    String? providerResponse,
    DateTime? responseDate,
  }) {
    return Review(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      providerId: providerId ?? this.providerId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      date: date ?? this.date,
      serviceType: serviceType ?? this.serviceType,
      images: images ?? this.images,
      isVerified: isVerified ?? this.isVerified,
      likes: likes ?? this.likes,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      providerResponse: providerResponse ?? this.providerResponse,
      responseDate: responseDate ?? this.responseDate,
    );
  }
}
