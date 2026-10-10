class User {
  final String id;
  final String email;
  final String? fullName;
  final String? preferredName;
  final String? phoneNumber;
  final String? location;
  final String? city;
  final String? stateRegion;
  final String? country;
  final String? countryCode;
  final String? timeZone;
  final String? industry;
  final String? linkedin;
  final String? github;
  final String? portfolioUrl;
  final List<Map<String, dynamic>>? customLinks;
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
  final bool useNameForNewResumes;
  final bool useTitleForNewResumes;
  final bool useLocationForNewResumes;
  final bool suggestLinksForNewResumes;
  final int version;
  final int completenessPercentage;
  final List<String> missingRequiredFields;
  final List<String> missingRecommendedFields;
  final String? verifiedPhone;
  final bool isPhoneVerified;
  final String? verifiedEmail;
  final bool isEmailVerified;

  String? get professionalTitle => title;
  String? get profilePictureUrl => profileImage;

  User({
    required this.id,
    required this.email,
    this.fullName,
    this.preferredName,
    this.phoneNumber,
    this.location,
    this.city,
    this.stateRegion,
    this.country,
    this.countryCode,
    this.timeZone,
    this.industry,
    this.linkedin,
    this.github,
    this.portfolioUrl,
    this.customLinks,
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
    this.useNameForNewResumes = true,
    this.useTitleForNewResumes = true,
    this.useLocationForNewResumes = true,
    this.suggestLinksForNewResumes = true,
    this.version = 1,
    this.completenessPercentage = 0,
    this.missingRequiredFields = const [],
    this.missingRecommendedFields = const [],
    this.verifiedPhone,
    this.isPhoneVerified = false,
    this.verifiedEmail,
    this.isEmailVerified = false,
  });

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? preferredName,
    String? phoneNumber,
    String? location,
    String? city,
    String? stateRegion,
    String? country,
    String? countryCode,
    String? timeZone,
    String? industry,
    String? linkedin,
    String? github,
    String? portfolioUrl,
    List<Map<String, dynamic>>? customLinks,
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
    bool? useNameForNewResumes,
    bool? useTitleForNewResumes,
    bool? useLocationForNewResumes,
    bool? suggestLinksForNewResumes,
    int? version,
    int? completenessPercentage,
    List<String>? missingRequiredFields,
    List<String>? missingRecommendedFields,
    String? verifiedPhone,
    bool? isPhoneVerified,
    String? verifiedEmail,
    bool? isEmailVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      preferredName: preferredName ?? this.preferredName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      city: city ?? this.city,
      stateRegion: stateRegion ?? this.stateRegion,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      timeZone: timeZone ?? this.timeZone,
      industry: industry ?? this.industry,
      linkedin: linkedin ?? this.linkedin,
      github: github ?? this.github,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      customLinks: customLinks ?? this.customLinks,
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
      useNameForNewResumes: useNameForNewResumes ?? this.useNameForNewResumes,
      useTitleForNewResumes: useTitleForNewResumes ?? this.useTitleForNewResumes,
      useLocationForNewResumes:
          useLocationForNewResumes ?? this.useLocationForNewResumes,
      suggestLinksForNewResumes:
          suggestLinksForNewResumes ?? this.suggestLinksForNewResumes,
      version: version ?? this.version,
      completenessPercentage:
          completenessPercentage ?? this.completenessPercentage,
      missingRequiredFields:
          missingRequiredFields ?? this.missingRequiredFields,
      missingRecommendedFields:
          missingRecommendedFields ?? this.missingRecommendedFields,
      verifiedPhone: verifiedPhone ?? this.verifiedPhone,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      verifiedEmail: verifiedEmail ?? this.verifiedEmail,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  String get maskedPhone {
    final raw = verifiedPhone ?? phoneNumber ?? '';
    if (raw.isEmpty) return 'No phone number attached';
    if (raw.length <= 4) return '•••• $raw';
    final last4 = raw.substring(raw.length - 4);
    final prefix = raw.startsWith('+') ? raw.substring(0, 3) : '';
    return prefix.isNotEmpty ? '$prefix ••••• $last4' : '••••• $last4';
  }
}
