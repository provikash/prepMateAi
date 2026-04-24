import '../../domain/models/ats_analysis.dart';

class AtsState {
  final AtsAnalysis? analysis;
  final bool isLoading;
  final String? error;

  AtsState({
    this.analysis,
    this.isLoading = false,
    this.error,
  });

  AtsState copyWith({
    AtsAnalysis? analysis,
    bool? isLoading,
    String? error,
  }) {
    return AtsState(
      analysis: analysis ?? this.analysis,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
