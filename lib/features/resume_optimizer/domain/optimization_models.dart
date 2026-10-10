enum RequirementMatch { matched, partial, missing, unclear }

enum SuggestionStatus { pending, accepted, rejected, edited }

enum SuggestionFilter { all, pending, accepted, edited, rejected, critical }

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
    this.severity = 'MEDIUM',
    this.requiresConfirmation = false,
    this.decisionVersion = 1,
    this.targetItemId,
    this.targetChildId,
    this.targetField = '',
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
  final String severity;
  final bool requiresConfirmation;
  final int decisionVersion;
  final String? targetItemId;
  final String? targetChildId;
  final String targetField;

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
        .map((value) => value.toString())
        .toList();
    return OptimizationSuggestion(
      id: json['id']?.toString() ?? '',
      section: path.split('.').first,
      current: json['original_value']?.toString() ?? '',
      proposed:
          json['final_value']?.toString() ??
          json['ai_suggestion']?.toString() ??
          '',
      reason: json['reason']?.toString() ?? '',
      keywords: (json['keywords'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      evidence: evidence.join(', '),
      status: status,
      resumePath: path,
      evidencePaths: evidence,
      severity: json['severity']?.toString() ?? 'MEDIUM',
      requiresConfirmation: json['requires_confirmation'] == true,
      decisionVersion: (json['decision_version'] as num?)?.toInt() ?? 1,
      targetItemId: json['target_item_id']?.toString(),
      targetChildId: json['target_child_id']?.toString(),
      targetField: json['target_field']?.toString() ?? '',
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
      severity: severity,
      requiresConfirmation: requiresConfirmation,
      decisionVersion: decisionVersion,
      targetItemId: targetItemId,
      targetChildId: targetChildId,
      targetField: targetField,
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
    this.sourceResumeVersion = 1,
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
  final int sourceResumeVersion;

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
    sourceResumeVersion: sourceResumeVersion,
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
    this.finalAnalysisJson,
    this.sourceResumeVersion = 1,
    this.suggestions = const [],
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.decisionCounts = const {},
    this.optimizedVersionId,
    this.pdfUrl,
  });

  final String id;
  final String sourceResumeId;
  final String sourceResumeTitle;
  final String status;
  final JobDescriptionModel? jobDescription;
  final Map<String, dynamic>? analysisJson;
  final Map<String, dynamic>? matchResultsJson;
  final Map<String, dynamic>? finalAnalysisJson;
  final int sourceResumeVersion;
  final List<OptimizationSuggestion> suggestions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final Map<String, int> decisionCounts;
  final String? optimizedVersionId;
  final String? pdfUrl;

  factory OptimizationSessionModel.fromJson(Map<String, dynamic> json) {
    final rawDecisions = json['decision_counts'];
    final Map<String, int> decisions = {};
    if (rawDecisions is Map) {
      rawDecisions.forEach((k, v) {
        if (v is num) decisions[k.toString()] = v.toInt();
      });
    }

    final rawOptVersion = json['optimized_version'];
    String? optId;
    if (rawOptVersion is Map) {
      optId = rawOptVersion['id']?.toString();
    } else if (rawOptVersion != null) {
      optId = rawOptVersion.toString();
    }

    final rawPdf = json['pdf'];
    String? pdf;
    if (rawPdf is Map) {
      pdf = rawPdf['url']?.toString() ?? rawPdf['pdf_url']?.toString();
    } else if (rawPdf is String) {
      pdf = rawPdf;
    }

    DateTime? parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v);
        } catch (_) {}
      }
      return null;
    }

    return OptimizationSessionModel(
      id: json['id']?.toString() ?? '',
      sourceResumeId: json['source_resume_id']?.toString() ?? '',
      sourceResumeTitle: json['source_resume_title'] as String? ?? 'Resume',
      status: json['status'] as String? ?? 'DRAFT',
      jobDescription: json['job_description'] is Map<String, dynamic>
          ? JobDescriptionModel.fromJson(
              json['job_description'] as Map<String, dynamic>,
            )
          : null,
      analysisJson: json['analysis_json'] as Map<String, dynamic>?,
      matchResultsJson: json['match_results_json'] as Map<String, dynamic>?,
      finalAnalysisJson: json['final_analysis_json'] as Map<String, dynamic>?,
      sourceResumeVersion:
          (json['source_resume_version'] as num?)?.toInt() ?? 1,
      suggestions: (json['suggestions'] as List<dynamic>? ?? const [])
          .map(
            (item) => OptimizationSuggestion.fromApi(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      completedAt: parseDate(json['completed_at']),
      decisionCounts: decisions,
      optimizedVersionId: optId,
      pdfUrl: pdf,
    );
  }
}

class OptimizedVersionDetail {
  const OptimizedVersionDetail({
    required this.id,
    required this.title,
    this.targetRole = '',
    this.targetCompany = '',
    this.templateName = 'Professional',
    this.templateVersion = 1,
    this.pdfStatus = 'ready',
    this.changes = const [],
    this.sourceData = const {},
    this.data = const {},
    this.pdfUrl,
    this.pdfGeneratedAt,
    this.sourceResumeTitle = '',
    this.sourceResumeVersion = 1,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String targetRole;
  final String targetCompany;
  final String templateName;
  final int templateVersion;
  final String pdfStatus;
  final List<dynamic> changes;
  final Map<String, dynamic> sourceData;
  final Map<String, dynamic> data;
  final String? pdfUrl;
  final String? pdfGeneratedAt;
  final String sourceResumeTitle;
  final int sourceResumeVersion;
  final String? createdAt;
  final String? updatedAt;

  factory OptimizedVersionDetail.fromApi(Map<String, dynamic> json) {
    return OptimizedVersionDetail(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      targetRole: json['target_role']?.toString() ?? '',
      targetCompany: json['target_company']?.toString() ?? '',
      templateName: json['template_name']?.toString() ?? 'Professional',
      templateVersion: (json['template_version'] as num?)?.toInt() ?? 1,
      pdfStatus: json['pdf_status']?.toString().toLowerCase() ?? 'ready',
      changes: (json['changes'] as List<dynamic>? ?? const [])
          .map(
            (c) => c is Map
                ? OptimizationSuggestion.fromApi(Map<String, dynamic>.from(c))
                : c,
          )
          .toList(),
      sourceData: json['source_data'] is Map
          ? Map<String, dynamic>.from(json['source_data'] as Map)
          : const {},
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
      pdfUrl: json['pdf_url']?.toString(),
      pdfGeneratedAt: json['pdf_generated_at']?.toString(),
      sourceResumeTitle: json['source_resume_title']?.toString() ?? '',
      sourceResumeVersion:
          (json['source_resume_version'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class OptimizationSummaryData {
  const OptimizationSummaryData({
    required this.sessionId,
    required this.status,
    this.targetRole = '',
    this.company = '',
    this.sourceResumeId = '',
    this.sourceResumeTitle = '',
    this.sourceResumeVersion = 1,
    this.currentSourceVersion = 1,
    this.isSourceStale = false,
    this.readyToCreate = false,
    this.stats = const {},
    this.sections = const [],
    this.hasConflicts = false,
    this.outputConfig = const {},
    this.alignmentScore = 0,
    this.atsReadiness,
    this.optimizedVersionId,
    this.pdfStatus,
  });

  final String sessionId;
  final String status;
  final String targetRole;
  final String company;
  final String sourceResumeId;
  final String sourceResumeTitle;
  final int sourceResumeVersion;
  final int currentSourceVersion;
  final bool isSourceStale;
  final bool readyToCreate;
  final Map<String, dynamic> stats;
  final List<dynamic> sections;
  final bool hasConflicts;
  final Map<String, dynamic> outputConfig;
  final int alignmentScore;
  final dynamic atsReadiness;
  final String? optimizedVersionId;
  final String? pdfStatus;

  factory OptimizationSummaryData.fromApi(Map<String, dynamic> json) {
    return OptimizationSummaryData(
      sessionId: json['session_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      targetRole: json['target_role']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      sourceResumeId: json['source_resume_id']?.toString() ?? '',
      sourceResumeTitle: json['source_resume_title']?.toString() ?? '',
      sourceResumeVersion:
          (json['source_resume_version'] as num?)?.toInt() ?? 1,
      currentSourceVersion:
          (json['current_source_version'] as num?)?.toInt() ?? 1,
      isSourceStale: json['is_source_stale'] == true,
      readyToCreate: json['ready_to_create'] == true,
      stats: json['stats'] is Map
          ? Map<String, dynamic>.from(json['stats'] as Map)
          : const {},
      sections: json['sections'] is List ? json['sections'] as List : const [],
      hasConflicts: json['has_conflicts'] == true,
      outputConfig: json['output_config'] is Map
          ? Map<String, dynamic>.from(json['output_config'] as Map)
          : const {},
      alignmentScore: (json['alignment_score'] as num?)?.toInt() ?? 0,
      atsReadiness: json['ats_readiness'],
      optimizedVersionId: json['optimized_version_id']?.toString(),
      pdfStatus: json['pdf_status']?.toString(),
    );
  }
}
