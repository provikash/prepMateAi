import 'dart:io';
import '../../data/models/resume_analysis_model.dart';

abstract class ResumeAnalyzerRepository {
  Future<ResumeAnalysisModel> analyzeResume({
    String? resumeId,
    File? file,
    required String jobRole,
  });

  Future<List<ResumeAnalysisModel>> getHistory();

  Future<ResumeAnalysisModel> getAnalysisDetail(String analysisId);

  Future<ResumeAnalysisModel> reanalyze({
    required String analysisId,
    String? jobRole,
  });
}
