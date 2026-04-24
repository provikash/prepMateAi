import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/dio_client.dart';
import '../../data/models/course_model.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../domain/repositories/course_repository.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/video_player_screen.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CourseRepositoryImpl(dio);
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final openedCoursesProvider = StateNotifierProvider<OpenedCoursesNotifier, Map<String, int>>((ref) {
  return OpenedCoursesNotifier(ref);
});

class OpenedCoursesNotifier extends StateNotifier<Map<String, int>> {
  final Ref _ref;
  static const _key = 'opened_courses_progress';

  OpenedCoursesNotifier(this._ref) : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    final data = prefs.getString(_key);
    if (data != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(data);
        state = decoded.map((key, value) => MapEntry(key, value as int));
      } catch (e) {
        state = {};
      }
    }
  }

  Future<void> updateProgress(String id, int percentage) async {
    // Only update if progress has increased to avoid unnecessary writes
    if ((state[id] ?? 0) < percentage) {
      final newState = {...state, id: percentage};
      state = newState;
      final prefs = await _ref.read(sharedPreferencesProvider.future);
      await prefs.setString(_key, jsonEncode(state));
    }
  }

  Future<void> markAsOpened(String id) async {
    if (!state.containsKey(id)) {
      await updateProgress(id, 0);
    }
  }
}

final courseListProvider = AsyncNotifierProvider<CourseListNotifier, CourseCategoryResponse>(() {
  return CourseListNotifier();
});

class CourseListNotifier extends AsyncNotifier<CourseCategoryResponse> {
  @override
  Future<CourseCategoryResponse> build() async {
    final repo = ref.watch(courseRepositoryProvider);
    final response = await repo.getCourses();
    final progressMap = ref.watch(openedCoursesProvider);

    return CourseCategoryResponse(
      continueLearning: _mapProgress(response.continueLearning, progressMap),
      careerGrowth: _mapProgress(response.careerGrowth, progressMap),
      technicalSkills: _mapProgress(response.technicalSkills, progressMap),
      softSkills: _mapProgress(response.softSkills, progressMap),
    );
  }

  List<Course> _mapProgress(List<Course> courses, Map<String, int> progressMap) {
    return courses.map((c) {
      final progress = progressMap[c.id];
      return c.copyWith(
        isOpened: progress != null,
        progressPercentage: progress ?? c.progressPercentage,
      );
    }).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final courseActionProvider = Provider((ref) => CourseActionHandler(ref));

class CourseActionHandler {
  final Ref _ref;
  CourseActionHandler(this._ref);

  Future<void> openCourse(BuildContext context, Course course) async {
    if (course.type == CourseType.youtubeVideo || course.type == CourseType.playlist) {
      // Option A: Open embedded player for both videos and playlists
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(course: course),
        ),
      );
    } else if (course.type == CourseType.pdf) {
      // Open embedded PDF viewer
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(course: course),
        ),
      );
      await _ref.read(openedCoursesProvider.notifier).markAsOpened(course.id);
    } else {
      // Fallback for other types (Drive, External Links)
      final url = Uri.parse(course.url);
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          await _ref.read(openedCoursesProvider.notifier).markAsOpened(course.id);
        } else {
          throw 'Could not launch $url';
        }
      } catch (e) {
        rethrow;
      }
    }
  }
}
