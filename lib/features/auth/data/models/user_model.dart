import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.email,
    super.fullName,
    super.preferredName,
    super.phoneNumber,
    super.location,
    super.city,
    super.stateRegion,
    super.country,
    super.countryCode,
    super.timeZone,
    super.industry,
    super.linkedin,
    super.github,
    super.portfolioUrl,
    super.customLinks,
    super.skills,
    super.bio,
    super.title,
    super.profileImage,
    super.profileCompleted,
    super.onboardingCompleted,
    super.experienceLevel,
    super.careerInterests,
    super.careerGoals,
    super.targetRoles,
    super.onboardingStep = 1,
    super.useNameForNewResumes = true,
    super.useTitleForNewResumes = true,
    super.useLocationForNewResumes = true,
    super.suggestLinksForNewResumes = true,
    super.version = 1,
    super.completenessPercentage = 0,
    super.missingRequiredFields = const [],
    super.missingRecommendedFields = const [],
    super.verifiedPhone,
    super.isPhoneVerified = false,
    super.verifiedEmail,
    super.isEmailVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>>? parsedLinks;
    if (json['custom_links'] is List) {
      parsedLinks = (json['custom_links'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? json['username'],
      preferredName: json['preferred_name'],
      phoneNumber: json['phone_number'] ?? json['phone'],
      location: json['location'],
      city: json['city'],
      stateRegion: json['state_region'],
      country: json['country'],
      countryCode: json['country_code'],
      timeZone: json['time_zone'],
      industry: json['industry'],
      linkedin: json['linkedin_url'] ?? json['linkedin'],
      github: json['github_url'] ?? json['github'],
      portfolioUrl: json['portfolio_url'],
      customLinks: parsedLinks,
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      bio: json['bio'],
      title: json['headline'] ?? json['job_title'] ?? json['title'],
      profileImage:
          json['profile_image_url'] ??
          json['profile_image'] ??
          json['avatar_url'],
      profileCompleted:
          json['profile_completed'] == true ||
          json['onboarding_completed'] == true,
      onboardingCompleted:
          json['onboarding_completed'] == true ||
          json['profile_completed'] == true,
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
      useNameForNewResumes: json['use_name_for_new_resumes'] ?? true,
      useTitleForNewResumes: json['use_title_for_new_resumes'] ?? true,
      useLocationForNewResumes: json['use_location_for_new_resumes'] ?? true,
      suggestLinksForNewResumes: json['suggest_links_for_new_resumes'] ?? true,
      version: (json['version'] as num?)?.toInt() ?? 1,
      completenessPercentage:
          (json['completeness_percentage'] as num?)?.toInt() ?? 0,
      missingRequiredFields: (json['missing_required_fields'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      missingRecommendedFields:
          (json['missing_recommended_fields'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
      verifiedPhone: json['verified_phone']?.toString(),
      isPhoneVerified: json['is_phone_verified'] == true,
      verifiedEmail: json['verified_email']?.toString(),
      isEmailVerified: json['is_email_verified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'preferred_name': preferredName,
      'phone': phoneNumber,
      'location': location,
      'city': city,
      'state_region': stateRegion,
      'country': country,
      'country_code': countryCode,
      'time_zone': timeZone,
      'industry': industry,
      'linkedin': linkedin,
      'github': github,
      'portfolio_url': portfolioUrl,
      'custom_links': customLinks,
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
      'use_name_for_new_resumes': useNameForNewResumes,
      'use_title_for_new_resumes': useTitleForNewResumes,
      'use_location_for_new_resumes': useLocationForNewResumes,
      'suggest_links_for_new_resumes': suggestLinksForNewResumes,
      'version': version,
    };
  }

  @override
  UserModel copyWith({
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
    return UserModel(
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
}

