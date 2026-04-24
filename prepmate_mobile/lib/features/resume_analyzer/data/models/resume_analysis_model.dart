class ResumeAnalysisModel {
  final String analysisId;
  final int atsScore;
  final int skillScore;
  final List<String> missingSections;
  final Map<String, List<String>> missingSkills;
  final Map<String, List<String>> matchedSkills;
  final KeywordAnalysis keywordAnalysis;
  final List<String> formatIssues;
  final List<String> contactIssues;
  final List<String> suggestions;
  final Map<String, dynamic> atsBreakdown;
  final String jobRole;
  final String? resumeId;
  final DateTime createdAt;

  ResumeAnalysisModel({
    required this.analysisId,
    required this.atsScore,
    required this.skillScore,
    required this.missingSections,
    required this.missingSkills,
    required this.matchedSkills,
    required this.keywordAnalysis,
    required this.formatIssues,
    required this.contactIssues,
    required this.suggestions,
    required this.atsBreakdown,
    required this.jobRole,
    this.resumeId,
    required this.createdAt,
  });

  factory ResumeAnalysisModel.fromJson(Map<String, dynamic> json) {
    return ResumeAnalysisModel(
      analysisId: json['analysis_id'].toString(),
      atsScore: json['ats_score'] ?? 0,
      skillScore: json['skill_score'] ?? 0,
      missingSections: List<String>.from(json['missing_sections'] ?? []),
      missingSkills: (json['missing_skills'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, List<String>.from(v)),
          ) ?? {},
      matchedSkills: (json['matched_skills'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, List<String>.from(v)),
          ) ?? {},
      keywordAnalysis: KeywordAnalysis.fromJson(json['keyword_analysis'] ?? {}),
      formatIssues: List<String>.from(json['format_issues'] ?? []),
      contactIssues: List<String>.from(json['contact_issues'] ?? []),
      suggestions: List<String>.from(json['suggestions'] ?? []),
      atsBreakdown: json['ats_breakdown'] ?? {},
      jobRole: json['job_role'] ?? '',
      resumeId: json['resume_id']?.toString(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class KeywordAnalysis {
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final double matchPercentage;

  KeywordAnalysis({
    required this.matchedKeywords,
    required this.missingKeywords,
    required this.matchPercentage,
  });

  factory KeywordAnalysis.fromJson(Map<String, dynamic> json) {
    return KeywordAnalysis(
      matchedKeywords: List<String>.from(json['matched_keywords'] ?? []),
      missingKeywords: List<String>.from(json['missing_keywords'] ?? []),
      matchPercentage: (json['match_percentage'] ?? 0).toDouble(),
    );
  }
}
