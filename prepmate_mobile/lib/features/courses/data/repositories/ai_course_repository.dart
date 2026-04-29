import 'package:dio/dio.dart';
import '../models/recommendation_model.dart';

class AICourseRepository {
  final Dio _dio;

  AICourseRepository(this._dio);

  Future<List<Recommendation>> getRecommendations(List<String> skills) async {
    try {
      final response = await _dio.post(
        'course-recommendations/recommendations/',
        data: {'skills': skills},
      );
      final List results = response.data['results'];
      return results.map((json) => Recommendation.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<CourseProgress> getProgress(String videoId) async {
    try {
      final response = await _dio.get('course-recommendations/progress/$videoId/');
      return CourseProgress.fromJson(response.data);
    } catch (e) {
      return CourseProgress(videoId: videoId, watchedSeconds: 0, totalSeconds: 0);
    }
  }

  Future<void> updateProgress(String videoId, int watchedSeconds, int totalSeconds) async {
    try {
      await _dio.post(
        'course-recommendations/progress/',
        data: {
          'video_id': videoId,
          'watched_seconds': watchedSeconds,
          'total_seconds': totalSeconds,
        },
      );
    } catch (e) {
      // Log error but don't disrupt playback
    }
  }
}
