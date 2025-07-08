class SignupData {
  final String email;
  final String password;
  final String name;
  final String phone;
  // Add any other fields you need

  SignupData({
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
  });

  Map<String, String> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
    };
  }
}
