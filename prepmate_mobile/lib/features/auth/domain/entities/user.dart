class User {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? location;
  final String? linkedin;
  final String? github;
  final List<String>? skills;
  final String? bio;
  final String? title;
  final String? profileImage;

  User({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.location,
    this.linkedin,
    this.github,
    this.skills,
    this.bio,
    this.title,
    this.profileImage,
  });

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? location,
    String? linkedin,
    String? github,
    List<String>? skills,
    String? bio,
    String? title,
    String? profileImage,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      linkedin: linkedin ?? this.linkedin,
      github: github ?? this.github,
      skills: skills ?? this.skills,
      bio: bio ?? this.bio,
      title: title ?? this.title,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
