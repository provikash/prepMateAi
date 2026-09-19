import 'package:dio/dio.dart';

import 'package:prepmate_mobile/features/home/data/models/resume_model.dart';
import '../domain/optimization_models.dart';
import '../domain/optimization_repository.dart';

class ApiOptimizationRepository implements OptimizationRepository {
  ApiOptimizationRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<ResumeModel>> getResumes() async {
    final response = await _dio.get('resumes/');
      final dynamic data = response.data;
      final List<dynamic> list = data is List
          ? data
          : (data is Map && data['results'] is List ? data['results'] as List : []);

    return list
          .map((item) => ResumeModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
  }

  @override
  Future<JobDescriptionModel> createJobDescription({
    required String title,
    required String company,
    required String description,
    String? sourceUrl,
  }) async {
    final response = await _dio.post(
      'job-optimizer/job-descriptions/',
      data: {
        'title': title,
        'company': company,
        'description': description,
        'source_url': sourceUrl ?? '',
      },
    );
    return JobDescriptionModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<OptimizationSessionModel> createOptimizationSession({
    required String resumeId,
    required String jobDescriptionId,
  }) async {
    final response = await _dio.post(
      'job-optimizer/sessions/',
      data: {
        'resume_id': resumeId,
        'job_description_id': jobDescriptionId,
      },
    );
    return OptimizationSessionModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<OptimizationSessionModel> getOptimizationSession(String sessionId) async {
    final response = await _dio.get('job-optimizer/sessions/$sessionId/');
    return OptimizationSessionModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<OptimizationSessionModel> analyzeJobDescription(String sessionId) async {
    final response = await _dio.post('job-optimizer/sessions/$sessionId/analyze/');
    return OptimizationSessionModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<OptimizationSessionModel> matchRequirements(String sessionId) async {
    final response = await _dio.post('job-optimizer/sessions/$sessionId/match/');
    return OptimizationSessionModel.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<OptimizationAnalysis> analyze({
    required String resumeId,
    required String jobDescription,
    String? jobTitle,
    String? company,
  }) async {
    // 1. Create Job Description
    final jd = await createJobDescription(
      title: jobTitle ?? '',
      company: company ?? '',
      description: jobDescription,
    );

    // 2. Create Optimization Session
    final session = await createOptimizationSession(
      resumeId: resumeId,
      jobDescriptionId: jd.id,
    );

    // 3. Analyze Job Description
    await analyzeJobDescription(session.id);

    // 4. Match Requirements against Resume
    final matchedSession = await matchRequirements(session.id);

    // 5. Parse response into OptimizationAnalysis
    return _parseSessionToAnalysis(matchedSession);
  }

  OptimizationAnalysis _parseSessionToAnalysis(OptimizationSessionModel session) {
    final analysisJson = session.analysisJson ?? {};
    final matchJson = session.matchResultsJson ?? {};

    final summary = matchJson['summary'] as Map<String, dynamic>? ?? {};
    final rawResults = (matchJson['results'] as List<dynamic>?) ?? [];

    final requirements = rawResults.map((raw) {
      final item = Map<String, dynamic>.from(raw as Map);
      final rawStatus = (item['status'] as String? ?? 'MISSING').toUpperCase();

      final match = switch (rawStatus) {
        'MATCHED' => RequirementMatch.matched,
        'PARTIAL' => RequirementMatch.partial,
        'UNCLEAR' => RequirementMatch.unclear,
        _ => RequirementMatch.missing,
      };

      String? evidenceStr;
      String? evidencePath;
      String? evidenceContext;

      final evidenceList = item['evidence'] as List<dynamic>?;
      if (evidenceList != null && evidenceList.isNotEmpty) {
        final first = Map<String, dynamic>.from(evidenceList.first as Map);
        evidenceStr = first['text'] as String?;
        evidencePath = first['path'] as String?;
        evidenceContext = '${first['section'] ?? ''} → ${first['context'] ?? ''}'.trim();
      }

      return JobRequirement(
        id: item['id']?.toString() ?? '',
        name: item['name'] as String? ?? '',
        importance: item['importance'] as String? ?? 'Required',
        category: item['category'] as String? ?? 'Technical Skill',
        match: match,
        explanation: item['explanation'] as String? ?? '',
        evidence: evidenceStr,
        evidencePath: evidencePath,
        evidenceContext: evidenceContext,
        sourceText: item['source_text'] as String?,
      );
    }).toList();

    final overview = JobAnalysisOverview(
      jobTitle: analysisJson['job_title'] as String? ?? '',
      company: analysisJson['company'] as String? ?? '',
      seniority: analysisJson['seniority'] as String? ?? '',
      requiredSkills: List<String>.from(analysisJson['required_skills'] ?? []),
      preferredSkills: List<String>.from(analysisJson['preferred_skills'] ?? []),
      responsibilities: List<String>.from(analysisJson['responsibilities'] ?? []),
      qualifications: List<String>.from(analysisJson['qualifications'] ?? []),
      experienceRequirements: List<String>.from(analysisJson['experience_requirements'] ?? []),
      keywords: (analysisJson['keywords'] as List<dynamic>?)
              ?.map((k) => (k is Map ? k['keyword']?.toString() : k.toString()) ?? '')
              .where((k) => k.isNotEmpty)
              .toList() ??
          [],
      softSkills: List<String>.from(analysisJson['soft_skills'] ?? []),
      domainTerms: List<String>.from(analysisJson['domain_terms'] ?? []),
    );

    final alignmentScore = (summary['alignment_score'] as num?)?.toInt() ?? 0;
    final total = (summary['total_requirements'] as num?)?.toInt() ?? requirements.length;
    final matched = (summary['matched'] as num?)?.toInt() ??
        requirements.where((r) => r.match == RequirementMatch.matched).length;
    final partial = (summary['partial'] as num?)?.toInt() ??
        requirements.where((r) => r.match == RequirementMatch.partial).length;
    final missing = (summary['missing'] as num?)?.toInt() ??
        requirements.where((r) => r.match == RequirementMatch.missing).length;
    final unclear = (summary['unclear'] as num?)?.toInt() ??
        requirements.where((r) => r.match == RequirementMatch.unclear).length;

    return OptimizationAnalysis(
      beforeScore: alignmentScore,
      afterScore: alignmentScore,
      requirements: requirements,
      suggestions: const [],
      overview: overview,
      totalRequirements: total,
      matchedCount: matched,
      partialCount: partial,
      missingCount: missing,
      unclearCount: unclear,
      sessionId: session.id,
    );
  }

  @override
  Future<String> regenerate(String text, String instruction) async {
    throw UnsupportedError('AI suggestions are not available yet.');
  }

  @override
  Future<void> createVersion(String name) async {
    throw UnsupportedError('Creating an optimized version is not available yet.');
  }

  @override
  Future<List<OptimizationSuggestion>> generateSuggestions(String sessionId) async {
    final response = await _dio.post('job-optimizer/sessions/$sessionId/suggestions/generate/');
    return (response.data as List<dynamic>)
        .map((value) => OptimizationSuggestion.fromApi(Map<String, dynamic>.from(value as Map)))
        .toList();
  }

  @override
  Future<OptimizationSuggestion> reviewSuggestion(
    String id, SuggestionStatus status, {String? value}
  ) async {
    final action = switch (status) {
      SuggestionStatus.accepted => 'accept',
      SuggestionStatus.rejected => 'reject',
      SuggestionStatus.edited => 'edit',
      SuggestionStatus.pending => throw ArgumentError('Pending is not a review action.'),
    };
    final response = await _dio.post(
      'job-optimizer/suggestions/$id/$action/',
      data: value == null ? null : {'value': value},
    );
    return OptimizationSuggestion.fromApi(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<OptimizationSuggestion> regenerateSuggestion(String id, String instruction) async {
    final key = 'regen-$id-${DateTime.now().microsecondsSinceEpoch}';
    final response = await _dio.post(
      'job-optimizer/suggestions/$id/regenerate/',
      data: {'instruction': instruction},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    return OptimizationSuggestion.fromApi(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<Map<String, dynamic>> finalizeOptimization(String sessionId, String name) async {
    final response = await _dio.post(
      'job-optimizer/sessions/$sessionId/finalize/', data: {'name': name},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<int> getAvailableCredits() async {
    final info = await getCreditInfo();
    return (info['available_credits'] as num).toInt();
  }

  @override
  Future<Map<String, dynamic>> getCreditInfo() async {
    final response = await _dio.get('ai/credits/');
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<List<int>> getOptimizedPdf(String versionId) async {
    final response = await _dio.get<List<int>>(
      'job-optimizer/versions/$versionId/pdf/',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const [];
  }
}
