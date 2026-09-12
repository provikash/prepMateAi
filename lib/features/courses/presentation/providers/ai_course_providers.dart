import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/dio_client.dart';
import '../../../resume_analyzer/presentation/providers/resume_analyzer_providers.dart';
import '../../data/models/recommendation_model.dart';
import '../../data/repositories/ai_course_repository.dart';

final aiCourseRepositoryProvider = Provider<AICourseRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AICourseRepository(dio);
});

final skillGapProvider = Provider<List<String>>((ref) {
  final analysisState = ref.watch(historyProvider);
  return analysisState.when(
    data: (history) {
      if (history.isEmpty) return [];
      // Take the most recent analysis
      final latest = history.first;
      final List<String> skills = [];
      latest.missingSkills.values.forEach(skills.addAll);
      return skills.take(5).toList(); // Take top 5 missing skills
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final recommendationsProvider = AsyncNotifierProvider<RecommendationsNotifier, List<Recommendation>>(() {
  return RecommendationsNotifier();
});

class RecommendationsNotifier extends AsyncNotifier<List<Recommendation>> {
  @override
  Future<List<Recommendation>> build() async {
    final skills = ref.watch(skillGapProvider);
    if (skills.isEmpty) return [];
    
    final repo = ref.watch(aiCourseRepositoryProvider);
    return repo.getRecommendations(skills);
  }

  Future<void> search(List<String> skills) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(aiCourseRepositoryProvider);
      return repo.getRecommendations(skills);
    });
  }
}

final videoProgressProvider = FutureProvider.family<CourseProgress, String>((ref, videoId) async {
  final repo = ref.watch(aiCourseRepositoryProvider);
  return repo.getProgress(videoId);
});
