import 'dart:io';
import 'package:dio/dio.dart';
import '../../domain/repositories/resume_analyzer_repository.dart';
import '../models/resume_analysis_model.dart';
import '../../../../core/cache/cache_store.dart';

class ResumeAnalyzerRepositoryImpl implements ResumeAnalyzerRepository {
  final Dio _dio;
  final CacheCoordinator cache;
  final String? Function() userId;

  ResumeAnalyzerRepositoryImpl(
    this._dio, {
    required this.cache,
    required this.userId,
  });

  @override
  Future<ResumeAnalysisModel> analyzeResume({
    String? resumeId,
    File? file,
    required String jobRole,
  }) async {
    FormData formData = FormData.fromMap({'job_role': jobRole});

    if (file != null) {
      formData.files.add(
        MapEntry(
          'uploaded_file',
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        ),
      );
    } else if (resumeId != null) {
      formData.fields.add(MapEntry('resume_id', resumeId));
    }

    final response = await _dio.post(
      'resume-analyzer/analyze/',
      data: formData,
    );

    final value = ResumeAnalysisModel.fromJson(response.data);
    await _storeDetail(value);
    await _invalidateHistory();
    return value;
  }

  @override
  Future<List<ResumeAnalysisModel>> getHistory() async {
    final id = userId();
    if (id == null) return _fetchHistory();
    return cache.get(
      key: CacheKeyFactory.user(id, 'ats_history', const {'page': 1}),
      userId: id,
      policy: CachePolicy.atsHistory,
      decode: (value) => (value! as List)
          .map(
            (item) => ResumeAnalysisModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      encode: (value) => value.map((item) => item.toJson()).toList(),
      remote: _fetchHistory,
    );
  }

  Future<List<ResumeAnalysisModel>> _fetchHistory() async {
    final response = await _dio.get('resume-analyzer/history/');
    return (response.data as List)
        .map((json) => ResumeAnalysisModel.fromJson(json))
        .toList();
  }

  @override
  Future<ResumeAnalysisModel> getAnalysisDetail(String analysisId) async {
    final id = userId();
    if (id == null) return _fetchDetail(analysisId);
    return cache.get(
      key: CacheKeyFactory.user(id, 'ats_detail', {'id': analysisId}),
      userId: id,
      policy: CachePolicy.atsHistory,
      decode: (value) => ResumeAnalysisModel.fromJson(
        Map<String, dynamic>.from(value! as Map),
      ),
      encode: (value) => value.toJson(),
      remote: () => _fetchDetail(analysisId),
    );
  }

  Future<ResumeAnalysisModel> _fetchDetail(String analysisId) async {
    final response = await _dio.get('resume-analyzer/$analysisId/');
    return ResumeAnalysisModel.fromJson(response.data);
  }

  @override
  Future<ResumeAnalysisModel> reanalyze({
    required String analysisId,
    String? jobRole,
  }) async {
    final response = await _dio.post(
      'resume-analyzer/$analysisId/reanalyze/',
      data: jobRole != null ? {'job_role': jobRole} : null,
    );
    final value = ResumeAnalysisModel.fromJson(response.data);
    await _storeDetail(value);
    await _invalidateHistory();
    return value;
  }

  Future<void> _storeDetail(ResumeAnalysisModel value) async {
    final id = userId();
    if (id == null) return;
    await cache.put(
      key: CacheKeyFactory.user(id, 'ats_detail', {'id': value.analysisId}),
      userId: id,
      policy: CachePolicy.atsHistory,
      value: value,
      encode: (item) => item.toJson(),
    );
  }

  Future<void> _invalidateHistory() async {
    final id = userId();
    if (id == null) return;
    await cache.store.remove(
      CacheKeyFactory.user(id, 'ats_history', const {'page': 1}),
    );
  }
}
