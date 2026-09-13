import 'dart:io';
import 'package:dio/dio.dart';
import 'package:prepmate_mobile/features/resume_analyzer/data/models/resume_analysis_model.dart';
import 'package:prepmate_mobile/features/resume_analyzer/data/models/resume_model.dart';

class ResumeAnalyzerRemoteDataSource {
  final Dio _dio;

  ResumeAnalyzerRemoteDataSource(this._dio);

  Future<List<ResumeModel>> getResumes() async {
    final response = await _dio.get('resume-analyzer/resumes/');
    return (response.data as List)
        .map((json) => ResumeModel.fromJson(json))
        .toList();
  }

  Future<ResumeAnalysisModel> analyzeResume({
    required String jobRole,
    String? resumeId,
    File? uploadedFile,
  }) async {
    FormData formData = FormData.fromMap({
      'job_role': jobRole,
    });

    if (resumeId != null) {
      formData.fields.add(MapEntry('resume_id', resumeId));
    } else if (uploadedFile != null) {
      formData.files.add(MapEntry(
        'uploaded_file',
        await MultipartFile.fromFile(
          uploadedFile.path,
          filename: uploadedFile.path.split('/').last,
        ),
      ));
    }

    final response = await _dio.post(
      'resume-analyzer/analyze/',
      data: formData,
    );

    return ResumeAnalysisModel.fromJson(response.data);
  }

  Future<List<ResumeAnalysisModel>> getHistory() async {
    final response = await _dio.get('resume-analyzer/history/');
    return (response.data as List)
        .map((json) => ResumeAnalysisModel.fromJson(json))
        .toList();
  }

  Future<ResumeAnalysisModel> getAnalysisDetail(String analysisId) async {
    final response = await _dio.get('resume-analyzer/$analysisId/');
    return ResumeAnalysisModel.fromJson(response.data);
  }
}
