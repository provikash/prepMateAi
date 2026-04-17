import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.email,
    super.fullName,
    super.phoneNumber,
    super.location,
    super.linkedin,
    super.skills,
    super.bio,
    super.title,
    super.profileImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['username'],
      phoneNumber: json['phone_number'],
      location: json['location'],
      linkedin: json['linkedin'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      bio: json['bio'],
      title: json['title'],
      profileImage: json['profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'location': location,
      'linkedin': linkedin,
      'skills': skills,
      'bio': bio,
      'title': title,
      'profile_image': profileImage,
    };
  }
}
