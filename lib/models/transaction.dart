class Transaction {
  final String id;
  final double amount;
  final String clientName;
  final String serviceType;
  final DateTime timestamp; // Changed from 'date' to 'timestamp'
  final String status;
  final String paymentMethod;
  final String mpesaReference;
  final String? description;

  Transaction({
    required this.id,
    required this.amount,
    required this.clientName,
    required this.serviceType,
    required this.timestamp,
    required this.status,
    required this.paymentMethod,
    required this.mpesaReference,
    this.description,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'].toDouble(),
      clientName: json['clientName'],
      serviceType: json['serviceType'],
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'],
      paymentMethod: json['paymentMethod'],
      mpesaReference: json['mpesaReference'],
      description: json['description'],
    );
  }
}
