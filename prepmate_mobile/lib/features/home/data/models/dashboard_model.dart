class DashboardModel {
  final String latestResume;
  final int atsScore;
  final double skillGap;
  final String improvementImpact;
  final List<String> missingSkills;
  final String suggestedSkills;

  DashboardModel({
    required this.latestResume,
    required this.atsScore,
    required this.skillGap,
    required this.improvementImpact,
    required this.missingSkills,
    required this.suggestedSkills,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      latestResume: json['latest_resume'] as String? ?? 'No active resume',
      atsScore: json['ats_score'] as int? ?? 0,
      skillGap: (json['skill_gap'] as num?)?.toDouble() ?? 0.0,
      improvementImpact: json['improvement_impact'] as String? ?? '',
      missingSkills: List<String>.from(json['missing_skills'] ?? []),
      suggestedSkills: json['suggested_skills'] as String? ?? '',
    );
  }
}
