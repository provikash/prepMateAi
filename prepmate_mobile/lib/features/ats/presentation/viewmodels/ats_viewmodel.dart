import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/ats_analysis.dart';
import '../state/ats_state.dart';
import '../../../../config/dio_client.dart';

final atsViewModelProvider = StateNotifierProvider<AtsViewModel, AtsState>((ref) {
  return AtsViewModel(ref);
});

class AtsViewModel extends StateNotifier<AtsState> {
  final Ref _ref;

  AtsViewModel(this._ref) : super(AtsState()) {
    loadAtsAnalysis();
  }

  Future<void> loadAtsAnalysis() async {
    state = state.copyWith(isLoading: true);

    try {
      final dio = _ref.read(dioProvider);
      // Simulating API call for now or using actual endpoint if available
      // final response = await dio.get('ats/analysis/');
      
      // Mock data for initial implementation as requested by UI screenshot
      await Future.delayed(const Duration(seconds: 1));
      
      final mockAnalysis = AtsAnalysis(
        score: 78,
        status: "Your resume is doing well, but there's room for improvement!",
        role: "Senior Product Designer roles",
        insights: [
          AtsInsight(
            title: "Formatting Check",
            description: "Perfectly readable by major ATS systems.",
            status: InsightStatus.success,
          ),
          AtsInsight(
            title: "Keywords Matching",
            description: "Missing 4 crucial industry keywords.",
            status: InsightStatus.warning,
          ),
          AtsInsight(
            title: "Section Headings",
            description: "Standard headings detected successfully.",
            status: InsightStatus.success,
          ),
          AtsInsight(
            title: "Contact Information",
            description: "Missing LinkedIn profile URL.",
            status: InsightStatus.error,
          ),
        ],
      );

      state = state.copyWith(analysis: mockAnalysis, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
