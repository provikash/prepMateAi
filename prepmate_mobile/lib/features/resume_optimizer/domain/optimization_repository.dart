import 'package:prepmate_mobile/features/home/data/models/resume_model.dart';
import 'optimization_models.dart';

abstract interface class OptimizationRepository {
  Future<List<ResumeModel>> getResumes();
  Future<JobDescriptionModel> createJobDescription({
    required String title,
    required String company,
    required String description,
    String? sourceUrl,
  });
  Future<OptimizationSessionModel> createOptimizationSession({
    required String resumeId,
    required String jobDescriptionId,
  });
  Future<OptimizationSessionModel> getOptimizationSession(String sessionId);
  Future<OptimizationAnalysis> restoreOptimization(String sessionId);
  Future<OptimizationSessionModel> analyzeJobDescription(String sessionId);
  Future<OptimizationSessionModel> matchRequirements(String sessionId);
  Future<OptimizationAnalysis> analyze({
    required String resumeId,
    required String jobDescription,
    String? jobTitle,
    String? company,
  });
  Future<String> regenerate(String text, String instruction);
  Future<void> createVersion(String name);
  Future<List<OptimizationSuggestion>> generateSuggestions(String sessionId);
  Future<OptimizationSuggestion> reviewSuggestion(
    String id,
    SuggestionStatus status, {
    String? value,
    int? decisionVersion,
  });
  Future<OptimizationSuggestion> regenerateSuggestion(
    String id,
    String instruction,
  );
  Future<Map<String, dynamic>> finalizeOptimization(
    String sessionId,
    String name, {
    required String idempotencyKey,
    required int expectedSourceVersion,
  });
  Future<int> getAvailableCredits();
  Future<Map<String, dynamic>> getCreditInfo();
  Future<List<int>> getOptimizedPdf(String versionId);
}
