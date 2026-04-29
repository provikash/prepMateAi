import 'package:dio/dio.dart';
import '../models/ai_course_model.dart';

/// Repository for AI Course API calls
class CourseRepository {
  final Dio dio;

  CourseRepository({required this.dio});

  /// Get course recommendations based on skills
  Future<List<AICourse>> getCourseRecommendations({
    required List<String> skills,
  }) async {
    try {
      final response = await dio.post(
        'courses/recommendations/',
        data: {
          'skills': skills,
        },
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        return results
            .map((item) => AICourse.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Failed to fetch recommendations: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Dio error: ${e.message}');
    }
  }

  /// Get course progress for a specific video
  Future<CourseProgress> getCourseProgress({required String videoId}) async {
    try {
      final response = await dio.get(
        'courses/progress/$videoId/',
      );

      if (response.statusCode == 200) {
        return CourseProgress.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw Exception('Failed to fetch progress: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Dio error: ${e.message}');
    }
  }

  /// Get all course progress for current user
  Future<List<CourseProgress>> getAllCourseProgress() async {
    try {
      final response = await dio.get('courses/progress/');

      if (response.statusCode == 200) {
        final results = response.data as List;
        return results
            .map((item) => CourseProgress.fromJson(item as Map<String, dynamic>))
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
        return CourseProgress.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw Exception('Failed to update progress: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Dio error: ${e.message}');
    }
  }
}
