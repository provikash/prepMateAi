import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/data/models/resume_model.dart';
import '../../data/mock_optimization_repository.dart';
import '../../domain/optimization_models.dart';
import '../../domain/optimization_repository.dart';

class OptimizationState {
  const OptimizationState({
    this.resume,
    this.jobDescription = '',
    this.company = 'TechNova',
    this.jobTitle = 'Senior Mobile Engineer',
    this.analysis,
    this.busy = false,
    this.analysisStage = 0,
    this.error,
    this.versionName = 'Software Developer — Optimized for TechNova',
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

  OptimizationState copyWith({
    ResumeModel? resume,
    String? jobDescription,
    String? company,
    String? jobTitle,
    OptimizationAnalysis? analysis,
    bool? busy,
    int? analysisStage,
    String? error,
    bool clearError = false,
    String? versionName,
  }) => OptimizationState(
    resume: resume ?? this.resume,
    jobDescription: jobDescription ?? this.jobDescription,
    company: company ?? this.company,
    jobTitle: jobTitle ?? this.jobTitle,
    analysis: analysis ?? this.analysis,
    busy: busy ?? this.busy,
    analysisStage: analysisStage ?? this.analysisStage,
    error: clearError ? null : error ?? this.error,
    versionName: versionName ?? this.versionName,
  );
}

final optimizationRepositoryProvider = Provider<OptimizationRepository>(
  (_) => MockOptimizationRepository(),
);
final optimizationProvider =
    StateNotifierProvider<OptimizationNotifier, OptimizationState>(
      (ref) => OptimizationNotifier(ref.read(optimizationRepositoryProvider)),
    );

class OptimizationNotifier extends StateNotifier<OptimizationState> {
  OptimizationNotifier(this._repository) : super(const OptimizationState());
  final OptimizationRepository _repository;
  void selectResume(ResumeModel value) =>
      state = state.copyWith(resume: value, clearError: true);
  void setJobDescription(String value) =>
      state = state.copyWith(jobDescription: value, clearError: true);
  void setVersionName(String value) =>
      state = state.copyWith(versionName: value);

  Future<bool> analyze() async {
    if (state.resume == null) {
      state = state.copyWith(error: 'Choose a resume before starting.');
      return false;
    }
    if (state.jobDescription.trim().length < 80) {
      state = state.copyWith(
        error: 'Paste a valid job description of at least 80 characters.',
      );
      return false;
    }
    state = state.copyWith(busy: true, analysisStage: 0, clearError: true);
    try {
      for (var step = 1; step < 4; step++) {
        await Future<void>.delayed(const Duration(milliseconds: 220));
        state = state.copyWith(analysisStage: step);
      }
      final result = await _repository.analyze(state.jobDescription);
      state = state.copyWith(analysis: result, busy: false, analysisStage: 4);
      return true;
    } catch (error) {
      state = state.copyWith(
        busy: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void setSuggestionStatus(String id, SuggestionStatus status) =>
      _update(id, (item) => item.copyWith(status: status));
  void editSuggestion(String id, String text) => _update(
    id,
    (item) => item.copyWith(proposed: text, status: SuggestionStatus.edited),
  );
  void acceptRecommended() {
    final a = state.analysis;
    if (a == null) return;
    state = state.copyWith(
      analysis: OptimizationAnalysis(
        beforeScore: a.beforeScore,
        afterScore: a.afterScore,
        requirements: a.requirements,
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
      analysis: OptimizationAnalysis(
        beforeScore: a.beforeScore,
        afterScore: a.afterScore,
        requirements: a.requirements,
        suggestions: a.suggestions
            .map((s) => s.id == id ? change(s) : s)
            .toList(),
      ),
    );
  }

  Future<String?> regenerate(String id, String instruction) async {
    final item = state.analysis!.suggestions.firstWhere((s) => s.id == id);
    try {
      final value = await _repository.regenerate(item.proposed, instruction);
      return value;
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> createVersion() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _repository.createVersion(state.versionName);
      state = state.copyWith(busy: false);
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
