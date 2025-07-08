class MpesaTransaction {
  final String id;
  final String providerId;
  final double amount;
  final String clientName;
  final String serviceType;
  final String status;
  final String paymentMethod;
  final String mpesaReference;
  final DateTime timestamp;
  final String? description;

  MpesaTransaction({
    required this.id,
    required this.providerId,
    required this.amount,
    required this.clientName,
    required this.serviceType,
    required this.status,
    required this.paymentMethod,
    required this.mpesaReference,
    required this.timestamp,
    this.description,
  });

  factory MpesaTransaction.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing transaction: ${json.toString()}'); // Debug log
      return MpesaTransaction(
        id: json['_id'] ?? json['id'] ?? '',
        providerId: json['providerId'] ?? '',
        amount: (json['amount'] ?? 0).toDouble(),
        clientName: json['clientName'] ?? 'Unknown Client',
        serviceType: json['serviceType'] ?? 'Unknown Service',
        status: json['status'] ?? 'pending',
        paymentMethod: json['paymentMethod'] ?? 'mpesa',
        mpesaReference: json['mpesaReference'] ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
        description: json['description'],
      );
    } catch (e) {
      print('Error parsing transaction: $e');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'amount': amount,
      'clientName': clientName,
      'serviceType': serviceType,
      'status': status,
      'paymentMethod': paymentMethod,
      'mpesaReference': mpesaReference,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
    };
  }
}
