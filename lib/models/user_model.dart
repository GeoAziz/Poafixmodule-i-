/// Represents a user in the system
class User {
  final String id;
  final String name;
  final String email;
  final String userType;
  final String phone;
  final String? token;
  final String avatarUrl; // Changed from profilePicUrl for consistency
  final String? phoneNumber; // For backward compatibility
  final String? profilePicUrl; // Add this
  final DateTime? createdAt; // Add this
  final String? preferredCommunication; // Add this
  final String? backupContact; // Add this
  final String? timezone; // Add this

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.phone = '',
    this.token,
    this.avatarUrl = '', // Made optional with default empty string
    this.phoneNumber,
    this.profilePicUrl,
    this.createdAt,
    this.preferredCommunication,
    this.backupContact,
    this.timezone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userType: json['userType'] ?? json['role'] ?? 'client',
      phone: json['phone'] ?? json['phoneNumber'] ?? '',
      token: json['token'],
      avatarUrl: json['avatarUrl'] ??
          json['profilePicUrl'] ??
          '', // Handle both field names
      phoneNumber: json['phoneNumber'] ?? json['phone'],
      profilePicUrl: json['profilePicUrl'] ?? json['avatarUrl'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      preferredCommunication: json['preferredCommunication'],
      backupContact: json['backupContact'],
      timezone: json['timezone'],
    );
  }

  // Add empty constructor for default values
  factory User.empty() {
    return User(
      id: '',
      name: '',
      email: '',
      userType: 'client',
      phone: '',
      token: '',
      avatarUrl: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'userType': userType,
      'phone': phone,
      'phoneNumber': phoneNumber ?? phone,
      'avatarUrl': avatarUrl,
      'token': token,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'userType': userType,
      'phone': phone,
      'phoneNumber': phoneNumber ?? phone,
      'avatarUrl': avatarUrl,
      'profilePicUrl': profilePicUrl,
      'createdAt': createdAt?.toIso8601String(),
      'preferredCommunication': preferredCommunication,
      'backupContact': backupContact,
      'timezone': timezone,
      'token': token,
    };
  }
}
