import 'package:dio/dio.dart';
import '../models/ai_course_model.dart';
import '../../../../core/cache/cache_store.dart';

/// Repository for AI Course API calls
class CourseRepository {
  final Dio dio;
  final CacheCoordinator cache;
  final String? Function() userId;

  CourseRepository({
    required this.dio,
    required this.cache,
    required this.userId,
  });

  /// Get course recommendations based on skills
  Future<List<AICourse>> getCourseRecommendations({
    required List<String> skills,
  }) {
    final normalized =
        skills
            .map((value) => value.trim().toLowerCase())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final id = userId();
    final key = id == null
        ? CacheKeyFactory.public('course_results', {
            'skills': normalized.join(','),
          })
        : CacheKeyFactory.user(id, 'course_results', {
            'skills': normalized.join(','),
          });
    return cache.get(
      key: key,
      userId: id,
      policy: CachePolicy.courseResults,
      decode: (value) => (value! as List)
          .map(
            (item) => AICourse.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      encode: (value) => value.map((item) => item.toJson()).toList(),
      remote: () => _fetchCourseRecommendations(normalized),
    );
  }

  Future<List<AICourse>> _fetchCourseRecommendations(
    List<String> skills,
  ) async {
    try {
      final response = await dio.post(
        'courses/recommendations/',
        data: {'skills': skills},
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        return results
            .map((item) => AICourse.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw Exception(
        'Failed to fetch recommendations: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception('Dio error: ${e.message}');
    }
  }

  /// Get course progress for a specific video
  Future<CourseProgress> getCourseProgress({required String videoId}) async {
    final id = userId();
    if (id != null) {
      return cache.get(
        key: CacheKeyFactory.user(id, 'course_progress', {'video': videoId}),
        userId: id,
        policy: CachePolicy.resumeList,
        decode: (value) =>
            CourseProgress.fromJson(Map<String, dynamic>.from(value! as Map)),
        encode: (value) => value.toJson(),
        remote: () => _fetchCourseProgress(videoId),
      );
    }
    return _fetchCourseProgress(videoId);
  }

  Future<CourseProgress> _fetchCourseProgress(String videoId) async {
    try {
      final response = await dio.get('courses/progress/$videoId/');

      if (response.statusCode == 200) {
        return CourseProgress.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Failed to fetch progress: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Dio error: ${e.message}');
    }
  }

  /// Get all course progress for current user
  Future<List<CourseProgress>> getAllCourseProgress() async {
    final id = userId();
    if (id != null) {
      return cache.get(
        key: CacheKeyFactory.user(id, 'course_progress_all'),
        userId: id,
        policy: CachePolicy.resumeList,
        decode: (value) => (value! as List)
            .map(
              (item) => CourseProgress.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
        encode: (value) => value.map((item) => item.toJson()).toList(),
        remote: _fetchAllCourseProgress,
      );
    }
    return _fetchAllCourseProgress();
  }

  Future<List<CourseProgress>> _fetchAllCourseProgress() async {
    try {
      final response = await dio.get('courses/progress/');

      if (response.statusCode == 200) {
        final results = response.data as List;
        return results
            .map(
              (item) => CourseProgress.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      throw Exception('Failed to fetch progress: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Dio error: ${e.message}');
    }
  }

  /// Update course progress
  Future<CourseProgress> updateCourseProgress({
    required String videoId,
    required int watchedSeconds,
    required int totalSeconds,
  }) async {
    try {
      final response = await dio.post(
        'courses/progress/',
        data: {
          'video_id': videoId,
          'watched_seconds': watchedSeconds,
          'total_seconds': totalSeconds,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final value = CourseProgress.fromJson(
          response.data as Map<String, dynamic>,
        );
        final id = userId();
        if (id != null) {
          await cache.put(
            key: CacheKeyFactory.user(id, 'course_progress', {
              'video': videoId,
            }),
            userId: id,
            policy: CachePolicy.resumeList,
            value: value,
            encode: (item) => item.toJson(),
          );
          await cache.store.remove(
            CacheKeyFactory.user(id, 'course_progress_all'),
          );
        }
        return value;
      }

      throw Exception('Failed to update progress: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Dio error: ${e.message}');
    }
  }
}
