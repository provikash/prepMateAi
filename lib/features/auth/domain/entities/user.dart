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
  final bool profileCompleted;
  final bool onboardingCompleted;
  final String? experienceLevel;
  final List<String>? careerInterests;
  final List<String>? careerGoals;
  final List<String>? targetRoles;
  final int onboardingStep;

  String? get professionalTitle => title;
  String? get profilePictureUrl => profileImage;

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
    this.profileCompleted = false,
    this.onboardingCompleted = false,
    this.experienceLevel,
    this.careerInterests,
    this.careerGoals,
    this.targetRoles,
    this.onboardingStep = 1,
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
    bool? profileCompleted,
    bool? onboardingCompleted,
    String? experienceLevel,
    List<String>? careerInterests,
    List<String>? careerGoals,
    List<String>? targetRoles,
    int? onboardingStep,
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
      profileCompleted: profileCompleted ?? this.profileCompleted,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      careerInterests: careerInterests ?? this.careerInterests,
      careerGoals: careerGoals ?? this.careerGoals,
      targetRoles: targetRoles ?? this.targetRoles,
      onboardingStep: onboardingStep ?? this.onboardingStep,
    );
  }
}
