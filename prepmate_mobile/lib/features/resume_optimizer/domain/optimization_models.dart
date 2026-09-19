enum RequirementMatch { matched, partial, missing, unclear }

enum SuggestionStatus { pending, accepted, rejected, edited }

class JobRequirement {
  const JobRequirement({
    required this.name,
    required this.importance,
    required this.match,
    required this.explanation,
    this.id = '',
    this.category = 'Technical Skill',
    this.evidence,
    this.evidencePath,
    this.evidenceContext,
    this.sourceText,
  });

  final String id;
  final String name;
  final String importance;
  final String category;
  final RequirementMatch match;
  final String explanation;
  final String? evidence;
  final String? evidencePath;
  final String? evidenceContext;
  final String? sourceText;
}

class JobAnalysisOverview {
  const JobAnalysisOverview({
    required this.jobTitle,
    required this.company,
    required this.seniority,
    required this.requiredSkills,
    required this.preferredSkills,
    required this.responsibilities,
    required this.qualifications,
    required this.experienceRequirements,
    required this.keywords,
    required this.softSkills,
    required this.domainTerms,
  });

  final String jobTitle;
  final String company;
  final String seniority;
  final List<String> requiredSkills;
  final List<String> preferredSkills;
  final List<String> responsibilities;
  final List<String> qualifications;
  final List<String> experienceRequirements;
  final List<String> keywords;
  final List<String> softSkills;
  final List<String> domainTerms;
}

class OptimizationSuggestion {
  const OptimizationSuggestion({
    required this.id,
    required this.section,
    required this.current,
    required this.proposed,
    required this.reason,
    required this.keywords,
    required this.evidence,
    this.highImpact = false,
    this.status = SuggestionStatus.pending,
    this.resumePath = '',
    this.evidencePaths = const [],
  });

  final String id;
  final String section;
  final String current;
  final String proposed;
  final String reason;
  final List<String> keywords;
  final String evidence;
  final bool highImpact;
  final SuggestionStatus status;
  final String resumePath;
  final List<String> evidencePaths;

  factory OptimizationSuggestion.fromApi(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString().toUpperCase();
    final status = switch (rawStatus) {
      'ACCEPTED' => SuggestionStatus.accepted,
      'REJECTED' => SuggestionStatus.rejected,
      'EDITED' => SuggestionStatus.edited,
      _ => SuggestionStatus.pending,
    };
    final path = json['resume_path']?.toString() ?? '';
    final evidence = (json['evidence_reference'] as List<dynamic>? ?? const [])
        .map((value) => value.toString()).toList();
    return OptimizationSuggestion(
      id: json['id']?.toString() ?? '',
      section: path.split('.').first,
      current: json['original_value']?.toString() ?? '',
      proposed: json['final_value']?.toString() ??
          json['ai_suggestion']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      keywords: (json['keywords'] as List<dynamic>? ?? const [])
          .map((value) => value.toString()).toList(),
      evidence: evidence.join(', '),
      status: status,
      resumePath: path,
      evidencePaths: evidence,
    );
  }

  OptimizationSuggestion copyWith({
    String? proposed,
    SuggestionStatus? status,
  }) {
    return OptimizationSuggestion(
      id: id,
      section: section,
      current: current,
      proposed: proposed ?? this.proposed,
      reason: reason,
      keywords: keywords,
      evidence: evidence,
      highImpact: highImpact,
      status: status ?? this.status,
      resumePath: resumePath,
      evidencePaths: evidencePaths,
    );
  }
}

class OptimizationAnalysis {
  const OptimizationAnalysis({
    required this.beforeScore,
    required this.afterScore,
    required this.requirements,
    required this.suggestions,
    this.overview,
    this.totalRequirements = 0,
    this.matchedCount = 0,
    this.partialCount = 0,
    this.missingCount = 0,
    this.unclearCount = 0,
    this.sessionId,
    this.beforeAtsScore,
    this.afterAtsScore,
  });

  final int beforeScore;
  final int afterScore;
  final List<JobRequirement> requirements;
  final List<OptimizationSuggestion> suggestions;
  final JobAnalysisOverview? overview;
  final int totalRequirements;
  final int matchedCount;
  final int partialCount;
  final int missingCount;
  final int unclearCount;
  final String? sessionId;
  final int? beforeAtsScore;
  final int? afterAtsScore;

  OptimizationAnalysis copyWith({
    int? afterScore,
    int? beforeAtsScore,
    int? afterAtsScore,
    List<OptimizationSuggestion>? suggestions,
  }) => OptimizationAnalysis(
    beforeScore: beforeScore,
    afterScore: afterScore ?? this.afterScore,
    requirements: requirements,
    suggestions: suggestions ?? this.suggestions,
    overview: overview,
    totalRequirements: totalRequirements,
    matchedCount: matchedCount,
    partialCount: partialCount,
    missingCount: missingCount,
    unclearCount: unclearCount,
    sessionId: sessionId,
    beforeAtsScore: beforeAtsScore ?? this.beforeAtsScore,
    afterAtsScore: afterAtsScore ?? this.afterAtsScore,
  );
}

class JobDescriptionModel {
  const JobDescriptionModel({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    this.sourceUrl = '',
  });

  final String id;
  final String title;
  final String company;
  final String description;
  final String sourceUrl;

  factory JobDescriptionModel.fromJson(Map<String, dynamic> json) {
    return JobDescriptionModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      company: json['company'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'company': company,
    'description': description,
    'source_url': sourceUrl,
  };
}

class OptimizationSessionModel {
  const OptimizationSessionModel({
    required this.id,
    required this.sourceResumeId,
    required this.sourceResumeTitle,
    required this.status,
    this.jobDescription,
    this.analysisJson,
    this.matchResultsJson,
  });

  final String id;
  final String sourceResumeId;
  final String sourceResumeTitle;
  final String status;
  final JobDescriptionModel? jobDescription;
  final Map<String, dynamic>? analysisJson;
  final Map<String, dynamic>? matchResultsJson;

  factory OptimizationSessionModel.fromJson(Map<String, dynamic> json) {
    return OptimizationSessionModel(
      id: json['id']?.toString() ?? '',
      sourceResumeId: json['source_resume_id']?.toString() ?? '',
      sourceResumeTitle: json['source_resume_title'] as String? ?? 'Resume',
      status: json['status'] as String? ?? 'DRAFT',
      jobDescription: json['job_description'] is Map<String, dynamic>
          ? JobDescriptionModel.fromJson(json['job_description'] as Map<String, dynamic>)
          : null,
      analysisJson: json['analysis_json'] as Map<String, dynamic>?,
      matchResultsJson: json['match_results_json'] as Map<String, dynamic>?,
    );
  }
}
