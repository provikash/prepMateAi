import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.email,
    super.fullName,
    super.phoneNumber,
    super.location,
    super.linkedin,
    super.github,
    super.skills,
    super.bio,
    super.title,
    super.profileImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? json['username'],
      phoneNumber: json['phone'] ?? json['phone_number'],
      location: json['location'],
      linkedin: json['linkedin'],
      github: json['github'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      bio: json['bio'],
      title: json['job_title'] ?? json['title'],
      profileImage:
          json['profile_image_url'] ??
          json['profile_image'] ??
          json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phoneNumber,
      'location': location,
      'linkedin': linkedin,
      'github': github,
      'skills': skills,
      'bio': bio,
      'job_title': title,
      'profile_image': profileImage,
    };
  }
}
