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
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      decisionCounts: decisions,
      optimizedVersionId: optId,
      pdfUrl: pdf,
    );
  }
}

class OptimizationSectionSummary {
  const OptimizationSectionSummary({
    required this.sectionName,
    required this.sectionKey,
    this.acceptedCount = 0,
    this.editedCount = 0,
    this.skippedCount = 0,
    this.pendingCount = 0,
    this.needsConfirmation = false,
    this.hasConflict = false,
    this.previewText = '',
    this.suggestionIds = const [],
  });

  final String sectionName;
  final String sectionKey;
  final int acceptedCount;
  final int editedCount;
  final int skippedCount;
  final int pendingCount;
  final bool needsConfirmation;
  final bool hasConflict;
  final String previewText;
  final List<String> suggestionIds;

  factory OptimizationSectionSummary.fromJson(Map<String, dynamic> json) {
    return OptimizationSectionSummary(
      sectionName: json['section_name'] as String? ?? 'Section',
      sectionKey: json['section_key'] as String? ?? '',
      acceptedCount: (json['accepted_count'] as num?)?.toInt() ?? 0,
      editedCount: (json['edited_count'] as num?)?.toInt() ?? 0,
      skippedCount: (json['skipped_count'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
      needsConfirmation: json['needs_confirmation'] == true,
      hasConflict: json['has_conflict'] == true,
      previewText: json['preview_text'] as String? ?? '',
      suggestionIds: (json['suggestions'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class OptimizationSummaryData {
  const OptimizationSummaryData({
    required this.sessionId,
    required this.status,
    required this.targetRole,
    required this.company,
    required this.sourceResumeId,
    required this.sourceResumeTitle,
    required this.sourceResumeVersion,
    required this.currentSourceVersion,
    required this.isSourceStale,
    required this.readyToCreate,
    required this.stats,
    required this.sections,
    this.hasConflicts = false,
    this.defaultName = '',
    this.selectedTemplateId,
    this.selectedTemplateName = 'Professional',
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
  final Map<String, int> stats;
  final List<OptimizationSectionSummary> sections;
  final bool hasConflicts;
  final String defaultName;
  final String? selectedTemplateId;
  final String selectedTemplateName;
  final int alignmentScore;
  final Map<String, dynamic>? atsReadiness;
  final String? optimizedVersionId;
  final String? pdfStatus;

  factory OptimizationSummaryData.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'];
    final Map<String, int> stats = {};
    if (rawStats is Map) {
      rawStats.forEach((k, v) {
        if (v is num) stats[k.toString()] = v.toInt();
      });
    }

    final rawSections = json['sections'] as List<dynamic>? ?? const [];
    final sections = rawSections
        .map(
          (s) => OptimizationSectionSummary.fromJson(
            Map<String, dynamic>.from(s as Map),
          ),
        )
        .toList();

    final outConfig = json['output_config'] as Map<String, dynamic>? ?? {};

    return OptimizationSummaryData(
      sessionId: json['session_id']?.toString() ?? '',
      status: json['status'] as String? ?? 'DRAFT',
      targetRole: json['target_role'] as String? ?? '',
      company: json['company'] as String? ?? '',
      sourceResumeId: json['source_resume_id']?.toString() ?? '',
      sourceResumeTitle: json['source_resume_title'] as String? ?? 'Resume',
      sourceResumeVersion:
          (json['source_resume_version'] as num?)?.toInt() ?? 1,
      currentSourceVersion:
          (json['current_source_version'] as num?)?.toInt() ?? 1,
      isSourceStale: json['is_source_stale'] == true,
      readyToCreate: json['ready_to_create'] == true,
      stats: stats,
      sections: sections,
      hasConflicts: json['has_conflicts'] == true,
      defaultName: outConfig['default_name'] as String? ?? 'Optimized Resume',
      selectedTemplateId: outConfig['selected_template_id']?.toString(),
      selectedTemplateName:
          outConfig['selected_template_name'] as String? ?? 'Professional',
      alignmentScore: (json['alignment_score'] as num?)?.toInt() ?? 0,
      atsReadiness: json['ats_readiness'] as Map<String, dynamic>?,
      optimizedVersionId: json['optimized_version_id']?.toString(),
      pdfStatus: json['pdf_status'] as String?,
    );
  }
}

class OptimizedVersionDetail {
  const OptimizedVersionDetail({
    required this.id,
    required this.title,
    required this.data,
    required this.sourceResumeId,
    required this.sourceResumeTitle,
    this.sourceResumeVersion = 1,
    this.sourceData = const {},
    this.templateId,
    this.templateName = 'Professional',
    this.templateVersion = 1,
    this.pdfStatus = 'not_requested',
    this.pdfUrl,
    this.pdfGeneratedAt,
    this.targetRole = '',
    this.targetCompany = '',
    this.changes = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final Map<String, dynamic> data;
  final String sourceResumeId;
  final String sourceResumeTitle;
  final int sourceResumeVersion;
  final Map<String, dynamic> sourceData;
  final String? templateId;
  final String templateName;
  final int templateVersion;
  final String pdfStatus;
  final String? pdfUrl;
  final DateTime? pdfGeneratedAt;
  final String targetRole;
  final String targetCompany;
  final List<OptimizationSuggestion> changes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory OptimizedVersionDetail.fromJson(Map<String, dynamic> json) {
    final rawChanges = json['changes'] as List<dynamic>? ?? const [];
    final changes = rawChanges
        .map(
          (c) => OptimizationSuggestion.fromApi(
            Map<String, dynamic>.from(c as Map),
          ),
        )
        .toList();

    return OptimizedVersionDetail(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Optimized Resume',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : {},
      sourceResumeId: json['source_resume_id']?.toString() ?? '',
      sourceResumeTitle:
          json['source_resume_title'] as String? ?? 'Master Resume',
      sourceResumeVersion:
          (json['source_resume_version'] as num?)?.toInt() ?? 1,
      sourceData: json['source_data'] is Map
          ? Map<String, dynamic>.from(json['source_data'] as Map)
          : {},
      templateId: json['template_id']?.toString(),
      templateName: json['template_name'] as String? ?? 'Professional',
      templateVersion: (json['template_version'] as num?)?.toInt() ?? 1,
      pdfStatus: json['pdf_status'] as String? ?? 'not_requested',
      pdfUrl: json['pdf_url'] as String?,
      pdfGeneratedAt: json['pdf_generated_at'] != null
          ? DateTime.tryParse(json['pdf_generated_at'].toString())
          : null,
      targetRole: json['target_role'] as String? ?? '',
      targetCompany: json['target_company'] as String? ?? '',
      changes: changes,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
