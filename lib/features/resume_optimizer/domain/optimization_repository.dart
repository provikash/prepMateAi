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
  Future<List<OptimizationSessionModel>> getOptimizationSessions({
    String? status,
    String? search,
    String? resumeId,
    String? ordering,
  });
  Future<void> deleteOptimizationSession(String sessionId);
  Future<OptimizationSessionModel> updateOptimizationSession(
    String sessionId,
    Map<String, dynamic> data,
  );
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
  Future<OptimizationSuggestion> confirmMissingSkill(
    String sessionId,
    String requirementId,
    String value,
  );
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
  Future<OptimizationSummaryData> getOptimizationSummary(String sessionId);
  Future<OptimizedVersionDetail> getOptimizedVersion(String versionId);
  Future<OptimizedVersionDetail> updateOptimizedVersion(
    String versionId, {
    String? title,
    String? templateId,
  });
  Future<Map<String, dynamic>> revertOptimizedChange(
    String versionId,
    String suggestionId,
  );
  Future<Map<String, dynamic>> submitBillingTicket({
    required String category,
    required String subject,
    required String message,
    String? transactionReference,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  });
  Future<int> getAvailableCredits();
  Future<Map<String, dynamic>> getCreditInfo();
  Future<List<int>> getOptimizedPdf(String versionId);
}
