import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({required super.id, required super.email, super.fullName});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['username'],
    );
  }
}
