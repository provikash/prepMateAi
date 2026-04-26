import 'dart:io';
import 'package:dio/dio.dart';
import '../../domain/repositories/resume_analyzer_repository.dart';
import '../models/resume_analysis_model.dart';

class ResumeAnalyzerRepositoryImpl implements ResumeAnalyzerRepository {
  final Dio _dio;

  ResumeAnalyzerRepositoryImpl(this._dio);

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
          'file',
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

    return ResumeAnalysisModel.fromJson(response.data);
  }

  @override
  Future<List<ResumeAnalysisModel>> getHistory() async {
    final response = await _dio.get('resume-analyzer/history/');
    return (response.data as List)
        .map((json) => ResumeAnalysisModel.fromJson(json))
        .toList();
  }

  @override
  Future<ResumeAnalysisModel> getAnalysisDetail(String analysisId) async {
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
    return ResumeAnalysisModel.fromJson(response.data);
  }
}
