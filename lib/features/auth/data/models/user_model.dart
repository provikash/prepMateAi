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
    super.profileCompleted,
    super.experienceLevel,
    super.careerInterests,
    super.careerGoals,
    super.targetRoles,
    super.onboardingStep = 1,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? json['username'],
      phoneNumber: json['phone_number'] ?? json['phone'],
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
      profileCompleted:
          json['profile_completed'] == true ||
          json['onboarding_completed'] == true,
      experienceLevel: json['experience_level'],
      careerInterests: json['career_interests'] != null
          ? List<String>.from(json['career_interests'])
          : null,
      careerGoals: json['career_goals'] != null
          ? List<String>.from(json['career_goals'])
          : null,
      targetRoles: json['target_roles'] != null
          ? List<String>.from(json['target_roles'])
          : null,
      onboardingStep: json['onboarding_step'] is int
          ? json['onboarding_step']
          : int.tryParse(json['onboarding_step']?.toString() ?? '') ?? 1,
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
      'profile_completed': profileCompleted,
      'experience_level': experienceLevel,
      'career_interests': careerInterests,
      'career_goals': careerGoals,
      'target_roles': targetRoles,
      'onboarding_step': onboardingStep,
    };
  }
}
