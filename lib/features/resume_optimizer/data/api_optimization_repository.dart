import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/cache/pdf_cache_store.dart';
import '../../../core/database/app_database.dart';
import 'package:prepmate_mobile/features/home/data/models/resume_model.dart';
import '../domain/optimization_models.dart';
import '../domain/optimization_repository.dart';

class ApiOptimizationRepository implements OptimizationRepository {
  ApiOptimizationRepository(
    this._dio, {
    required AppDatabase database,
    required PdfCacheStore pdfCache,
    required String? Function() userId,
  }) : _database = database,
       _pdfCache = pdfCache,
       _userId = userId;

  final Dio _dio;
  final AppDatabase _database;
  final PdfCacheStore _pdfCache;
  final String? Function() _userId;
  final Map<String, OptimizationSuggestion> _suggestions = {};

  @override
  Future<List<ResumeModel>> getResumes() async {
    final response = await _dio.get('resumes/');
    final dynamic data = response.data;
    final List<dynamic> list = data is List
        ? data
        : (data is Map && data['results'] is List
              ? data['results'] as List
              : []);

    return list
        .map(
          (item) =>
              ResumeModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
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
    return JobDescriptionModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<OptimizationSessionModel> createOptimizationSession({
    required String resumeId,
    required String jobDescriptionId,
  }) async {
    final response = await _dio.post(
      'job-optimizer/sessions/',
      data: {'resume_id': resumeId, 'job_description_id': jobDescriptionId},
    );
    return OptimizationSessionModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<OptimizationSessionModel> getOptimizationSession(
    String sessionId,
  ) async {
    final accountId = _userId();
    try {
      final response = await _dio.get('job-optimizer/sessions/$sessionId/');
      final json = Map<String, dynamic>.from(response.data as Map);
      final session = OptimizationSessionModel.fromJson(json);
      for (final item in session.suggestions) {
        _suggestions[item.id] = item;
      }
      if (accountId != null) {
        await _database
            .into(_database.optimizationSnapshots)
            .insertOnConflictUpdate(
              OptimizationSnapshotsCompanion.insert(
                cacheKey: '$accountId:$sessionId',
                userId: accountId,
                sessionId: sessionId,
                payload: jsonEncode(json),
                updatedAt: DateTime.now(),
              ),
            );
      }
      return session;
    } on DioException catch (error) {
      if (!_isOffline(error) || accountId == null) rethrow;
      final cached =
          await (_database.select(_database.optimizationSnapshots)
                ..where((row) => row.cacheKey.equals('$accountId:$sessionId')))
              .getSingleOrNull();
      if (cached == null) rethrow;
      final session = OptimizationSessionModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(cached.payload) as Map),
      );
      for (final item in session.suggestions) {
        _suggestions[item.id] = item;
      }
      return session;
    }
  }

  @override
  Future<List<OptimizationSessionModel>> getOptimizationSessions({
    String? status,
    String? search,
    String? resumeId,
    String? ordering,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (resumeId != null && resumeId.isNotEmpty) {
      queryParams['resume_id'] = resumeId;
    }
    if (ordering != null && ordering.isNotEmpty) {
      queryParams['ordering'] = ordering;
    }

    try {
      final response = await _dio.get(
        'job-optimizer/sessions/',
        queryParameters: queryParams,
      );
      final dynamic raw = response.data;
      final List<dynamic> list = raw is List
          ? raw
          : (raw is Map && raw['results'] is List
                ? raw['results'] as List
                : []);

      final sessions = list
          .map(
            (item) => OptimizationSessionModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      final accountId = _userId();
      if (accountId != null) {
        for (final session in sessions) {
          await _database
              .into(_database.optimizationSnapshots)
              .insertOnConflictUpdate(
                OptimizationSnapshotsCompanion.insert(
                  cacheKey: '$accountId:${session.id}',
                  userId: accountId,
                  sessionId: session.id,
                  payload: jsonEncode({
                    'id': session.id,
                    'source_resume_id': session.sourceResumeId,
                    'source_resume_title': session.sourceResumeTitle,
                    'status': session.status,
                    'job_description': session.jobDescription?.toJson(),
                    'analysis_json': session.analysisJson,
                    'match_results_json': session.matchResultsJson,
                    'source_resume_version': session.sourceResumeVersion,
                    'created_at': session.createdAt?.toIso8601String(),
                    'updated_at': session.updatedAt?.toIso8601String(),
                    'completed_at': session.completedAt?.toIso8601String(),
                  }),
                  updatedAt: DateTime.now(),
                ),
              );
        }
      }
      return sessions;
    } on DioException catch (error) {
      final accountId = _userId();
      if (!_isOffline(error) || accountId == null) rethrow;
      final cachedRows = await (_database.select(
        _database.optimizationSnapshots,
      )..where((row) => row.userId.equals(accountId))).get();
      return cachedRows.map((row) {
        final map = Map<String, dynamic>.from(jsonDecode(row.payload) as Map);
        return OptimizationSessionModel.fromJson(map);
      }).toList();
    }
  }

  @override
  Future<void> deleteOptimizationSession(String sessionId) async {
    await _dio.delete('job-optimizer/sessions/$sessionId/');
    final accountId = _userId();
    if (accountId != null) {
      await (_database.delete(
        _database.optimizationSnapshots,
      )..where((row) => row.cacheKey.equals('$accountId:$sessionId'))).go();
    }
  }

  @override
  Future<OptimizationSessionModel> updateOptimizationSession(
    String sessionId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      'job-optimizer/sessions/$sessionId/',
      data: data,
    );
    return OptimizationSessionModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<OptimizationAnalysis> restoreOptimization(String sessionId) async =>
      _parseSessionToAnalysis(await getOptimizationSession(sessionId));

  @override
  Future<OptimizationSessionModel> analyzeJobDescription(
    String sessionId,
  ) async {
    final response = await _dio.post(
      'job-optimizer/sessions/$sessionId/analyze/',
    );
    return OptimizationSessionModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<OptimizationSessionModel> matchRequirements(String sessionId) async {
    final response = await _dio.post(
      'job-optimizer/sessions/$sessionId/match/',
    );
    return OptimizationSessionModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
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

  OptimizationAnalysis _parseSessionToAnalysis(
    OptimizationSessionModel session,
  ) {
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
        evidenceContext =
            '${first['section'] ?? ''} → ${first['context'] ?? ''}'.trim();
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
      preferredSkills: List<String>.from(
        analysisJson['preferred_skills'] ?? [],
      ),
      responsibilities: List<String>.from(
        analysisJson['responsibilities'] ?? [],
      ),
      qualifications: List<String>.from(analysisJson['qualifications'] ?? []),
      experienceRequirements: List<String>.from(
        analysisJson['experience_requirements'] ?? [],
      ),
      keywords:
          (analysisJson['keywords'] as List<dynamic>?)
              ?.map(
                (k) =>
                    (k is Map ? k['keyword']?.toString() : k.toString()) ?? '',
              )
              .where((k) => k.isNotEmpty)
              .toList() ??
          [],
      softSkills: List<String>.from(analysisJson['soft_skills'] ?? []),
      domainTerms: List<String>.from(analysisJson['domain_terms'] ?? []),
    );

    final alignmentScore = (summary['alignment_score'] as num?)?.toInt() ?? 0;
    final total =
        (summary['total_requirements'] as num?)?.toInt() ?? requirements.length;
    final matched =
        (summary['matched'] as num?)?.toInt() ??
        requirements.where((r) => r.match == RequirementMatch.matched).length;
    final partial =
        (summary['partial'] as num?)?.toInt() ??
        requirements.where((r) => r.match == RequirementMatch.partial).length;
    final missing =
        (summary['missing'] as num?)?.toInt() ??
        requirements.where((r) => r.match == RequirementMatch.missing).length;
    final unclear =
        (summary['unclear'] as num?)?.toInt() ??
        requirements.where((r) => r.match == RequirementMatch.unclear).length;

    return OptimizationAnalysis(
      beforeScore: alignmentScore,
      afterScore: alignmentScore,
      requirements: requirements,
      suggestions: session.suggestions,
      overview: overview,
      totalRequirements: total,
      matchedCount: matched,
      partialCount: partial,
      missingCount: missing,
      unclearCount: unclear,
      sessionId: session.id,
      sourceResumeVersion: session.sourceResumeVersion,
    );
  }

  @override
  Future<String> regenerate(String text, String instruction) async {
    throw UnsupportedError('AI suggestions are not available yet.');
  }

  @override
  Future<void> createVersion(String name) async {
    throw UnsupportedError(
      'Creating an optimized version is not available yet.',
    );
  }

  @override
  Future<List<OptimizationSuggestion>> generateSuggestions(
    String sessionId,
  ) async {
    final key = 'generate-${DateTime.now().microsecondsSinceEpoch}';
    final response = await _dio.post(
      'job-optimizer/sessions/$sessionId/suggestions/generate/',
      options: Options(headers: {'Idempotency-Key': key}),
    );
    return (response.data as List<dynamic>)
        .map(
          (value) => OptimizationSuggestion.fromApi(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList()
      ..forEach((item) => _suggestions[item.id] = item);
  }

  @override
  Future<OptimizationSuggestion> confirmMissingSkill(
    String sessionId,
    String requirementId,
    String value,
  ) async {
    final response = await _dio.post(
      'job-optimizer/sessions/$sessionId/suggestions/confirm-missing-skill/',
      data: {'requirement_id': requirementId, 'value': value},
    );
    return OptimizationSuggestion.fromApi(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<OptimizationSuggestion> reviewSuggestion(
    String id,
    SuggestionStatus status, {
    String? value,
    int? decisionVersion,
  }) async {
    final action = switch (status) {
      SuggestionStatus.accepted => 'accept',
      SuggestionStatus.rejected => 'reject',
      SuggestionStatus.edited => 'edit',
      SuggestionStatus.pending => 'undo',
    };
    final data = {
      if (value != null) 'value': value,
      if (decisionVersion != null) 'decision_version': decisionVersion,
    };
    try {
      final response = await _dio.post(
        'job-optimizer/suggestions/$id/$action/',
        data: data,
      );
      final result = OptimizationSuggestion.fromApi(
        Map<String, dynamic>.from(response.data as Map),
      );
      _suggestions[id] = result;
      await _markOptimizerPdfsStale();
      return result;
    } on DioException catch (error) {
      final accountId = _userId();
      final current = _suggestions[id];
      if (!_isOffline(error) || accountId == null || current == null) rethrow;
      await _database
          .into(_database.mutationOutbox)
          .insert(
            MutationOutboxCompanion.insert(
              userId: accountId,
              entityType: 'suggestion_decision',
              entityLocalId: id,
              operation: action,
              payload: jsonEncode({
                'path': 'job-optimizer/suggestions/$id/$action/',
                'data': data,
              }),
              createdAt: DateTime.now(),
            ),
          );
      final queued = current.copyWith(proposed: value, status: status);
      _suggestions[id] = queued;
      await _markOptimizerPdfsStale();
      return queued;
    }
  }

  @override
  Future<OptimizationSuggestion> regenerateSuggestion(
    String id,
    String instruction,
  ) async {
    final key = 'regen-$id-${DateTime.now().microsecondsSinceEpoch}';
    final response = await _dio.post(
      'job-optimizer/suggestions/$id/regenerate/',
      data: {'instruction': instruction},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    return OptimizationSuggestion.fromApi(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<Map<String, dynamic>> finalizeOptimization(
    String sessionId,
    String name, {
    required String idempotencyKey,
    required int expectedSourceVersion,
  }) async {
    final response = await _dio.post(
      'job-optimizer/sessions/$sessionId/apply/',
      data: {
        'name': name,
        'idempotency_key': idempotencyKey,
        'expected_source_version': expectedSourceVersion,
      },
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<OptimizationSummaryData> getOptimizationSummary(
    String sessionId,
  ) async {
    final response = await _dio.get('job-optimizer/sessions/$sessionId/summary/');
    return OptimizationSummaryData.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<OptimizedVersionDetail> getOptimizedVersion(String versionId) async {
    final response = await _dio.get('job-optimizer/versions/$versionId/');
    return OptimizedVersionDetail.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<OptimizedVersionDetail> updateOptimizedVersion(
    String versionId, {
    String? title,
    String? templateId,
  }) async {
    final response = await _dio.patch(
      'job-optimizer/versions/$versionId/',
      data: {
        if (title != null) 'title': title,
        if (templateId != null) 'template_id': templateId,
      },
    );
    await _markOptimizerPdfsStale();
    return OptimizedVersionDetail.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<Map<String, dynamic>> revertOptimizedChange(
    String versionId,
    String suggestionId,
  ) async {
    final response = await _dio.post(
      'job-optimizer/versions/$versionId/revert/',
      data: {'suggestion_id': suggestionId},
    );
    await _markOptimizerPdfsStale();
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<Map<String, dynamic>> submitBillingTicket({
    required String category,
    required String subject,
    required String message,
    String? transactionReference,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {
    final key =
        idempotencyKey ?? 'ticket-${DateTime.now().microsecondsSinceEpoch}';
    final response = await _dio.post(
      'billing/support/tickets/',
      data: {
        'category': category,
        'subject': subject,
        'message': message,
        if (transactionReference != null)
          'transaction_reference': transactionReference,
        if (metadata != null) 'metadata': metadata,
        'idempotency_key': key,
      },
      options: Options(headers: {'Idempotency-Key': key}),
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
    final accountId = _userId();
    final cacheId = 'optimized-$versionId';
    if (accountId != null) {
      final metadata = await _pdfCache.metadata(accountId, cacheId);
      if (metadata != null && !metadata.stale) {
        final bytes = await _pdfCache.read(metadata);
        if (bytes != null) return bytes;
      }
    }
    final response = await _dio.get<List<int>>(
      'job-optimizer/versions/$versionId/pdf/',
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data ?? const <int>[];
    if (accountId != null && bytes.isNotEmpty) {
      await _pdfCache.write(
        userId: accountId,
        resumeId: cacheId,
        etag: response.headers.value('etag') ?? '',
        bytes: Uint8List.fromList(bytes),
      );
    }
    return bytes;
  }

  bool _isOffline(DioException error) =>
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.error is SocketException;

  Future<void> _markOptimizerPdfsStale() async {
    // Version identifiers are only known when a PDF is requested. The
    // metadata store safely marks matching cached optimizer exports stale.
    final accountId = _userId();
    if (accountId == null) return;
    await _pdfCache.markAllOptimizerPdfsStale(accountId);
  }
}
