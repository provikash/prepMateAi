class DashboardModel {
  final String latestResume;
  final int atsScore;
  final double skillGap;
  final String improvementImpact;
  final List<String> missingSkills;
  final String suggestedSkills;
  final bool analysisAvailable;
  final String message;
  final String userName;

  DashboardModel({
    required this.latestResume,
    required this.atsScore,
    required this.skillGap,
    required this.improvementImpact,
    required this.missingSkills,
    required this.suggestedSkills,
    required this.analysisAvailable,
    required this.message,
    required this.userName,
  });

  String get progressStatus => analysisAvailable ? 'Analyzed' : 'Draft';
  String get role => latestResume;
  double get progress => (atsScore / 100).clamp(0.0, 1.0);
  String get aiSuggestion => suggestedSkills.isNotEmpty
      ? 'Focus on: $suggestedSkills'
      : 'Analyze your resume to get personalized suggestions.';

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final rawLatestResume = json['latest_resume'];
    final latestResume = rawLatestResume is Map
        ? Map<String, dynamic>.from(rawLatestResume)
        : null;
    final missingSkillsRaw = json['missing_skills'] as List? ?? const [];
    final suggestedSkillsRaw = json['suggested_skills'] as List? ?? const [];
    final atsScore = (latestResume?['ats_score'] as num?)?.toInt() ?? 0;
    final skillGapPercentage =
        (latestResume?['skill_gap_percentage'] as num?)?.toDouble() ??
        (json['skill_gap_percentage'] as num?)?.toDouble() ??
        100.0;

    return DashboardModel(
      latestResume: latestResume?['title'] as String? ?? 'No active resume',
      atsScore: atsScore,
      skillGap: skillGapPercentage,
      improvementImpact:
          ((latestResume?['improvement_impact'] as num?)?.toInt() ??
                  (100 - atsScore).clamp(0, 100))
              .toString(),
      missingSkills: missingSkillsRaw.whereType<String>().toList(),
      suggestedSkills: suggestedSkillsRaw.whereType<String>().join(', '),
      analysisAvailable:
          json['analysis_available'] as bool? ?? latestResume != null,
      message: json['message'] as String? ?? '',
      userName: (json['full_name'] as String?) ?? 'User',
    );
  }

  Map<String, dynamic> toJson() => {
    'latest_resume': {
      'title': latestResume,
      'ats_score': atsScore,
      'skill_gap_percentage': skillGap,
      'improvement_impact': int.tryParse(improvementImpact) ?? 0,
    },
    'missing_skills': missingSkills,
    'suggested_skills': suggestedSkills
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(),
    'analysis_available': analysisAvailable,
    'message': message,
    'full_name': userName,
  };
}
