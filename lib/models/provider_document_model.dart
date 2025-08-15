class ProviderDocument {
  final String id;
  final String providerId;
  final String documentType;
  final String fileUrl;
  final String status; // pending, verified, rejected
  final DateTime uploadedAt;
  final DateTime? verifiedAt;
  final String? adminComment;
  final DateTime? expiryDate;
  final bool isExpired;

  ProviderDocument({
    required this.id,
    required this.providerId,
    required this.documentType,
    required this.fileUrl,
    required this.status,
    required this.uploadedAt,
    this.verifiedAt,
    this.adminComment,
    this.expiryDate,
  }) : isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());

  factory ProviderDocument.fromJson(Map<String, dynamic> json) {
    return ProviderDocument(
      id: json['_id'] ?? json['id'] ?? '',
      providerId: json['providerId']?.toString() ?? '',
      documentType: json['type'] ?? json['documentType'] ?? '',
      fileUrl: json['documentUrl'] ?? json['fileUrl'] ?? '',
      status: json['status'] ?? 'pending',
      uploadedAt: DateTime.parse(json['createdAt'] ?? json['uploadedAt']),
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'])
          : null,
      adminComment: json['verificationNotes'] ?? json['adminComment'],
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'providerId': providerId,
      'documentType': documentType,
      'fileUrl': fileUrl,
      'status': status,
      'uploadedAt': uploadedAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'adminComment': adminComment,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }
}
