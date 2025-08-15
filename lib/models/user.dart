import '../core/models/user_model.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String userType;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
  });

  factory User.fromUserModel(UserModel model) {
    return User(
      id: model.id,
      name: model.name,
      email: model.email,
      userType: model.userType,
    );
  }
}
