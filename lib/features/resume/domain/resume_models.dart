class ResumeData {
  final String summary;
  final List<Experience> experience;
  final List<String> skills;

  ResumeData({
    this.summary = '',
    this.experience = const [],
    this.skills = const [],
  });

  ResumeData copyWith({
    String? summary,
    List<Experience>? experience,
    List<String>? skills,
  }) {
    return ResumeData(
      summary: summary ?? this.summary,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
    );
  }

  factory ResumeData.fromJson(Map<String, dynamic> json) {
    return ResumeData(
      summary: json['summary'] ?? '',
      experience: (json['experience'] as List? ?? [])
          .map((e) => Experience.fromJson(e))
          .toList(),
      skills: List<String>.from(json['skills'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'experience': experience.map((e) => e.toJson()).toList(),
    'skills': skills,
  };
}

class Experience {
  final String jobTitle;
  final String company;
  final String duration;
  final String location;
  final List<String> bulletPoints;

  Experience({
    required this.jobTitle,
    required this.company,
    required this.duration,
    required this.location,
    this.bulletPoints = const [],
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      jobTitle: json['jobTitle'] ?? '',
      company: json['company'] ?? '',
      duration: json['duration'] ?? '',
      location: json['location'] ?? '',
      bulletPoints: List<String>.from(json['bulletPoints'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'jobTitle': jobTitle,
    'company': company,
    'duration': duration,
    'location': location,
    'bulletPoints': bulletPoints,
  };
}
