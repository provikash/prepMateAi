class ResumeData {
  String summary;
  List<ExperienceItem> experience;
  List<String> skills;

  ResumeData({
    this.summary = '',
    this.experience = const [],
    this.skills = const [],
  });

  ResumeData copyWith({
    String? summary,
    List<ExperienceItem>? experience,
    List<String>? skills,
  }) {
    return ResumeData(
      summary: summary ?? this.summary,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
    );
  }
}

class ExperienceItem {
  final String id;
  final String jobTitle;
  final String company;
  final String duration;
  final String location;
  final List<String> bulletPoints;

  ExperienceItem({
    required this.id,
    this.jobTitle = '',
    this.company = '',
    this.duration = '',
    this.location = '',
    this.bulletPoints = const [],
  });

  ExperienceItem copyWith({
    String? id,
    String? jobTitle,
    String? company,
    String? duration,
    String? location,
    List<String>? bulletPoints,
  }) {
    return ExperienceItem(
      id: id ?? this.id,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      bulletPoints: bulletPoints ?? this.bulletPoints,
    );
  }
}
