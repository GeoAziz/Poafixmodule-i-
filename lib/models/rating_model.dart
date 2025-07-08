class Rating {
  final String id;
  final String bookingId;
  final String providerId;
  final String clientId;
  final double score;
  final String comment;
  final DateTime createdAt;
  final String serviceType;
  final Map<String, double>? categoryRatings;

  Rating({
    required this.id,
    required this.bookingId,
    required this.providerId,
    required this.clientId,
    required this.score,
    required this.comment,
    required this.createdAt,
    required this.serviceType,
    this.categoryRatings,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['_id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      providerId: json['providerId'] ?? '',
      clientId: json['clientId'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      serviceType: json['serviceType'] ?? '',
      categoryRatings: json['categoryRatings'] != null
          ? Map<String, double>.from(json['categoryRatings'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'bookingId': bookingId,
        'providerId': providerId,
        'clientId': clientId,
        'score': score,
        'comment': comment,
        'serviceType': serviceType,
        'categoryRatings': categoryRatings,
      };
}
