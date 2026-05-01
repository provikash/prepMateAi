import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../config/dio_client.dart';
import '../../../resume_analyzer/presentation/providers/resume_analyzer_providers.dart';
import '../../data/models/ai_course_model.dart';
import '../../data/repositories/course_repository.dart';

import 'package:prepmate_mobile/features/resume_analyzer/presentation/providers/resume_analyzer_providers.dart' show historyProvider;

// ────────────────────────────────────────────────
// Repository Provider
// ────────────────────────────────────────────────

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CourseRepository(dio: dio);
});

// ────────────────────────────────────────────────
// State Notifiers
// ────────────────────────────────────────────────

class CourseRecommendationNotifier
    extends AsyncNotifier<List<AICourse>> {
  late CourseRepository _repository;

  @override
  Future<List<AICourse>> build() async {
    _repository = ref.watch(courseRepositoryProvider);
    final skills = ref.watch(skillGapProvider);
    if (skills.isEmpty) return [];
    return _repository.getCourseRecommendations(skills: skills);
  }

  Future<void> fetchRecommendations(List<String> skills) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _repository.getCourseRecommendations(skills: skills);
    });
  }
}

/// Provider for course recommendations
final courseRecommendationsProvider =
    AsyncNotifierProvider<CourseRecommendationNotifier, List<AICourse>>(
  () => CourseRecommendationNotifier(),
);

// ────────────────────────────────────────────────
// Course Progress Providers
// ────────────────────────────────────────────────

class CourseProgressNotifier extends FamilyAsyncNotifier<CourseProgress, String> {
  late CourseRepository _repository;

  @override
  Future<CourseProgress> build(String videoId) async {
    _repository = ref.watch(courseRepositoryProvider);
    return _repository.getCourseProgress(videoId: videoId);
  }

  Future<void> updateProgress({
    required int watchedSeconds,
    required int totalSeconds,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _repository.updateCourseProgress(
        videoId: arg,
        watchedSeconds: watchedSeconds,
        totalSeconds: totalSeconds,
      );
    });
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      return _repository.getCourseProgress(videoId: arg);
    });
  }
}

/// Provider for individual course progress
final courseProgressProvider = AsyncNotifierProvider.family<
    CourseProgressNotifier,
    CourseProgress,
    String>(() => CourseProgressNotifier());

/// Provider for all course progress
class AllCourseProgressNotifier extends AsyncNotifier<List<CourseProgress>> {
  late CourseRepository _repository;

  @override
  Future<List<CourseProgress>> build() async {
    _repository = ref.watch(courseRepositoryProvider);
    return _repository.getAllCourseProgress();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      return _repository.getAllCourseProgress();
    });
  }
}

final allCourseProgressProvider =
    AsyncNotifierProvider<AllCourseProgressNotifier, List<CourseProgress>>(
  () => AllCourseProgressNotifier(),
);

// ────────────────────────────────────────────────
// Skill Gap Data Provider (from Resume Analyzer)
// ────────────────────────────────────────────────

final skillGapProvider = Provider<List<String>>((ref) {
  final historyAsync = ref.watch(historyProvider);
  return historyAsync.when(
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

// ────────────────────────────────────────────────
// Video Player State Provider
// ────────────────────────────────────────────────

class VideoPlayerStateNotifier extends StateNotifier<String?> {
  VideoPlayerStateNotifier() : super(null);

  void setCurrentVideoId(String videoId) {
    state = videoId;
  }

  void clearCurrentVideo() {
    state = null;
  }
}

final currentVideoIdProvider =
    StateNotifierProvider<VideoPlayerStateNotifier, String?>(
  (ref) => VideoPlayerStateNotifier(),
);

// ────────────────────────────────────────────────
// Continue Learning (Recently Started Videos)
// ────────────────────────────────────────────────

final continueLearningProvider = FutureProvider<List<AICourse>>((ref) async {
  final allProgress = await ref.watch(allCourseProgressProvider.future);
  final recommendations = await ref.watch(courseRecommendationsProvider.future);

  // Filter to videos that have been started but not completed
  final continuing = allProgress.where((p) => p.hasStarted && !p.isCompleted);

  // Return corresponding course recommendations
  return recommendations
      .where((course) =>
          continuing.any((p) => p.videoId == course.videoId))
      .toList();
  });

//   Future<void> updateProgress(String id, int percentage) async {
//     // Only update if progress has increased to avoid unnecessary writes
//     if ((state[id] ?? 0) < percentage) {
//       final newState = {...state, id: percentage};
//       state = newState;
//       final prefs = await _ref.read(sharedPreferencesProvider.future);
//       await prefs.setString(_key, jsonEncode(state));
//     }
//   }

//   Future<void> markAsOpened(String id) async {
//     if (!state.containsKey(id)) {
//       await updateProgress(id, 0);
//     }
//   }
// }

// final courseListProvider =
//     AsyncNotifierProvider<CourseListNotifier, CourseCategoryResponse>(() {
//       return CourseListNotifier();
//     });

// class CourseListNotifier extends AsyncNotifier<CourseCategoryResponse> {
//   @override
//   Future<CourseCategoryResponse> build() async {
//     final repo = ref.watch(courseRepositoryProvider);
//     final response = await repo.getCourses();
//     final progressMap = ref.watch(openedCoursesProvider);

//     return CourseCategoryResponse(
//       continueLearning: _mapProgress(response.continueLearning, progressMap),
//       careerGrowth: _mapProgress(response.careerGrowth, progressMap),
//       technicalSkills: _mapProgress(response.technicalSkills, progressMap),
//       softSkills: _mapProgress(response.softSkills, progressMap),
//     );
//   }

//   List<Course> _mapProgress(
//     List<Course> courses,
//     Map<String, int> progressMap,
//   ) {
//     return courses.map((c) {
//       final progress = progressMap[c.id];
//       return c.copyWith(progress: progress ?? 0);
//     }).toList();
//   }

//   Future<void> refresh() async {
//     state = const AsyncLoading();
//     state = await AsyncValue.guard(() => build());
//   }
// }

// final courseActionProvider = Provider((ref) => CourseActionHandler(ref));

// class CourseActionHandler {
//   final Ref _ref;
//   CourseActionHandler(this._ref);

//   Future<void> openCourse(BuildContext context, Course course) async {
//     if (course.type == CourseType.youtubeVideo ||
//         course.type == CourseType.playlist) {
//       // Option A: Open embedded player for both videos and playlists
//       Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (context) => VideoPlayerScreen(course: course),
//         ),
//       );
//     } else if (course.type == CourseType.pdf) {
//       // Open embedded PDF viewer
//       Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (context) => PdfViewerScreen(course: course),
//         ),
//       );
//       await _ref.read(openedCoursesProvider.notifier).markAsOpened(course.id);
//     } else {
//       // Fallback for other types (Drive, External Links)
//       final url = Uri.parse(course.url);
//       try {
//         if (await canLaunchUrl(url)) {
//           await launchUrl(url, mode: LaunchMode.externalApplication);
//           await _ref
//               .read(openedCoursesProvider.notifier)
//               .markAsOpened(course.id);
//         } else {
//           throw 'Could not launch $url';
//         }
//       } catch (e) {
//         rethrow;
//       }
//     }
//   }
// }
