class Earnings {
  final double totalEarnings;
  final double pendingEarnings;

  Earnings({
    required this.totalEarnings,
    required this.pendingEarnings,
  });

  // Method to convert Earnings to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalEarnings': totalEarnings,
      'pendingEarnings': pendingEarnings,
    };
  }

  // Method to create Earnings from JSON
  factory Earnings.fromJson(Map<String, dynamic> json) {
    return Earnings(
      totalEarnings: json['totalEarnings'],
      pendingEarnings: json['pendingEarnings'],
    );
  }
}
