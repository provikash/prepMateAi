import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/dio_client.dart';
import '../../../home/data/models/resume_model.dart';
import '../../data/api_optimization_repository.dart';
import '../../data/mock_optimization_repository.dart';
import '../../domain/optimization_models.dart';
import '../../domain/optimization_repository.dart';

class OptimizationState {
  const OptimizationState({
    this.resume,
    this.jobDescription = '',
    this.company = '',
    this.jobTitle = '',
    this.analysis,
    this.busy = false,
    this.analysisStage = 0,
    this.error,
    this.versionName = 'Software Developer — Optimized',
    this.sessionId,
    this.credits,
    this.generationCost = 10,
    this.regenerationCost = 1,
    this.processingSuggestionId,
    this.finalizedVersionId,
  });

  final ResumeModel? resume;
  final String jobDescription;
  final String company;
  final String jobTitle;
  final OptimizationAnalysis? analysis;
  final bool busy;
  final int analysisStage;
  final String? error;
  final String versionName;
  final String? sessionId;
  final int? credits;
  final int generationCost;
  final int regenerationCost;
  final String? processingSuggestionId;
  final String? finalizedVersionId;

  OptimizationState copyWith({
    ResumeModel? resume,
    String? jobDescription,
    String? company,
    String? jobTitle,
    OptimizationAnalysis? analysis,
    bool clearAnalysis = false,
    bool? busy,
    int? analysisStage,
    String? error,
    bool clearError = false,
    String? versionName,
    String? sessionId,
    bool clearSession = false,
    int? credits,
    int? generationCost,
    int? regenerationCost,
    String? processingSuggestionId,
    bool clearProcessingSuggestion = false,
    String? finalizedVersionId,
    bool clearFinalizedVersion = false,
  }) => OptimizationState(
    resume: resume ?? this.resume,
    jobDescription: jobDescription ?? this.jobDescription,
    company: company ?? this.company,
    jobTitle: jobTitle ?? this.jobTitle,
    analysis: clearAnalysis ? null : analysis ?? this.analysis,
    busy: busy ?? this.busy,
    analysisStage: analysisStage ?? this.analysisStage,
    error: clearError ? null : error ?? this.error,
    versionName: versionName ?? this.versionName,
    sessionId: clearSession ? null : sessionId ?? this.sessionId,
    credits: credits ?? this.credits,
    generationCost: generationCost ?? this.generationCost,
    regenerationCost: regenerationCost ?? this.regenerationCost,
    processingSuggestionId: clearProcessingSuggestion
        ? null : processingSuggestionId ?? this.processingSuggestionId,
    finalizedVersionId: clearFinalizedVersion ? null : finalizedVersionId ?? this.finalizedVersionId,
  );
}

final useMockOptimizationProvider = StateProvider<bool>((ref) => false);

final optimizationRepositoryProvider = Provider<OptimizationRepository>((ref) {
  final useMock = ref.watch(useMockOptimizationProvider);
  if (useMock) {
    return MockOptimizationRepository();
  }
  final dio = ref.watch(dioProvider);
  return ApiOptimizationRepository(dio);
});

final optimizationProvider =
    StateNotifierProvider<OptimizationNotifier, OptimizationState>(
      (ref) => OptimizationNotifier(ref.watch(optimizationRepositoryProvider)),
    );

final optimizedVersionPdfProvider = FutureProvider.family<Uint8List, String>((ref, versionId) async {
  final bytes = await ref.watch(optimizationRepositoryProvider).getOptimizedPdf(versionId);
  return Uint8List.fromList(bytes);
});

class OptimizationNotifier extends StateNotifier<OptimizationState> {
  OptimizationNotifier(this._repository) : super(const OptimizationState());

  final OptimizationRepository _repository;

  void selectResume(ResumeModel value) =>
      state = state.copyWith(resume: value, clearError: true,
        clearAnalysis: true, clearSession: true, clearFinalizedVersion: true);

  void setJobTitle(String value) =>
      state = state.copyWith(jobTitle: value, clearError: true,
        clearAnalysis: true, clearSession: true, clearFinalizedVersion: true);

  void setCompany(String value) =>
      state = state.copyWith(company: value, clearError: true,
        clearAnalysis: true, clearSession: true, clearFinalizedVersion: true);

  void setJobDescription(String value) =>
      state = state.copyWith(jobDescription: value, clearError: true,
        clearAnalysis: true, clearSession: true, clearFinalizedVersion: true);

  void setVersionName(String value) =>
      state = state.copyWith(versionName: value);

  Future<bool> analyze() async {
    if (state.resume == null) {
      state = state.copyWith(error: 'Choose a resume before starting.');
      return false;
    }
    final trimmed = state.jobDescription.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(error: 'Please enter a job description.');
      return false;
    }
    if (trimmed.length < 80) {
      state = state.copyWith(
        error: 'Please provide a more complete job description of at least 80 characters.',
      );
      return false;
    }

    state = state.copyWith(busy: true, analysisStage: 0, clearError: true,
      clearAnalysis: true, clearSession: true, clearFinalizedVersion: true);
    try {
      // Animated progress stages
      for (var step = 1; step < 4; step++) {
        await Future<void>.delayed(const Duration(milliseconds: 220));
        state = state.copyWith(analysisStage: step);
      }

      final result = await _repository.analyze(
        resumeId: state.resume!.id,
        jobDescription: state.jobDescription,
        jobTitle: state.jobTitle.isEmpty ? null : state.jobTitle,
        company: state.company.isEmpty ? null : state.company,
      );

      state = state.copyWith(
        analysis: result,
        sessionId: result.sessionId,
        busy: false,
        analysisStage: 4,
        versionName: state.company.isNotEmpty
            ? '${state.resume!.title} — Optimized for ${state.company}'
            : '${state.resume!.title} — Optimized',
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        busy: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> loadCredits() async {
    try {
      final info = await _repository.getCreditInfo();
      final costs = info['operation_costs'] is Map
          ? Map<String, dynamic>.from(info['operation_costs'] as Map) : <String, dynamic>{};
      state = state.copyWith(
        credits: (info['available_credits'] as num?)?.toInt() ?? 0,
        generationCost: (costs['resume_optimization'] as num?)?.toInt() ?? 10,
        regenerationCost: (costs['suggestion_regeneration'] as num?)?.toInt() ?? 1,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  Future<bool> generateSuggestions() async {
    final sessionId = state.sessionId;
    if (sessionId == null || state.analysis == null) {
      state = state.copyWith(error: 'Run job analysis first.');
      return false;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      final suggestions = await _repository.generateSuggestions(sessionId);
      state = state.copyWith(
        analysis: state.analysis!.copyWith(suggestions: suggestions), busy: false,
      );
      await loadCredits();
      return true;
    } catch (error) {
      state = state.copyWith(busy: false, error: error.toString());
      return false;
    }
  }

  Future<bool> setSuggestionStatus(String id, SuggestionStatus status) async {
    if (_repository is MockOptimizationRepository) {
      _update(id, (item) => item.copyWith(status: status));
      return true;
    }
    state = state.copyWith(processingSuggestionId: id, clearError: true);
    try {
      final result = await _repository.reviewSuggestion(id, status);
      _update(id, (_) => result);
      state = state.copyWith(clearProcessingSuggestion: true);
      return true;
    } catch (error) {
      state = state.copyWith(clearProcessingSuggestion: true, error: error.toString());
      return false;
    }
  }

  Future<bool> editSuggestion(String id, String text) async {
    if (_repository is MockOptimizationRepository) {
      _update(id, (item) => item.copyWith(proposed: text, status: SuggestionStatus.edited));
      return true;
    }
    state = state.copyWith(processingSuggestionId: id, clearError: true);
    try {
      final result = await _repository.reviewSuggestion(
        id, SuggestionStatus.edited, value: text,
      );
      _update(id, (_) => result);
      state = state.copyWith(clearProcessingSuggestion: true);
      return true;
    } catch (error) {
      state = state.copyWith(clearProcessingSuggestion: true, error: error.toString());
      return false;
    }
  }

  void acceptRecommended() {
    if (_repository is! MockOptimizationRepository) return;
    final a = state.analysis;
    if (a == null) return;
    state = state.copyWith(
      analysis: a.copyWith(
        suggestions: a.suggestions
            .map(
              (s) => s.highImpact && s.status == SuggestionStatus.pending
                  ? s.copyWith(status: SuggestionStatus.accepted)
                  : s,
            )
            .toList(),
      ),
    );
  }

  void _update(
    String id,
    OptimizationSuggestion Function(OptimizationSuggestion) change,
  ) {
    final a = state.analysis;
    if (a == null) return;
    state = state.copyWith(
      analysis: a.copyWith(
        suggestions: a.suggestions
            .map((s) => s.id == id ? change(s) : s)
            .toList(),
      ),
    );
  }

  Future<String?> regenerate(String id, String instruction) async {
    try {
      if (_repository is MockOptimizationRepository) {
        final item = state.analysis!.suggestions.firstWhere((s) => s.id == id);
        return await _repository.regenerate(item.proposed, instruction);
      }
      state = state.copyWith(processingSuggestionId: id, clearError: true);
      final result = await _repository.regenerateSuggestion(id, instruction);
      _update(id, (_) => result);
      state = state.copyWith(clearProcessingSuggestion: true);
      await loadCredits();
      return result.proposed;
    } catch (error) {
      state = state.copyWith(
        clearProcessingSuggestion: true,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> createVersion() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      if (_repository is MockOptimizationRepository) {
        await _repository.createVersion(state.versionName);
        state = state.copyWith(busy: false);
        return true;
      }
      final sessionId = state.sessionId;
      if (sessionId == null) throw StateError('No optimization session is active.');
      final result = await _repository.finalizeOptimization(sessionId, state.versionName);
      final afterScore = (result['after_alignment_score'] as num?)?.toInt();
      final beforeAts = (result['before_ats_score'] as num?)?.toInt();
      final afterAts = (result['after_ats_score'] as num?)?.toInt();
      state = state.copyWith(
        busy: false,
        finalizedVersionId: result['resume_version_id']?.toString(),
        analysis: afterScore == null ? state.analysis
            : state.analysis?.copyWith(
                afterScore: afterScore,
                beforeAtsScore: beforeAts,
                afterAtsScore: afterAts,
              ),
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        busy: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}
