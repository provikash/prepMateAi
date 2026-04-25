import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/dio_client.dart';
import 'models/resume.dart';

// ==========================================
// 1. THE API PROVIDER
// ==========================================
final resumeApiProvider = Provider<ResumeApi>((ref) {
  final dio = ref.watch(dioProvider);
  return ResumeApi(dio);
});

// ==========================================
// 2. THE API CLASS
// ==========================================
class ResumeApi {
  final Dio _dio;

  ResumeApi(this._dio);

  // --- FETCH ALL RESUMES ---
  Future<List<Resume>> getResumes() async {
    try {
      final response = await _dio.get('/resumes/');

      // Handle both direct list response and paginated response (results key)
      final dynamic rawData = response.data;
      List<dynamic> listData;

      if (rawData is List) {
        listData = rawData;
      } else if (rawData is Map && rawData.containsKey('results')) {
        listData = rawData['results'];
      } else {
        // Fallback for unexpected data formats
        return [];
      }

      return listData.map((json) => Resume.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e, "Failed to fetch resumes");
    } catch (e) {
      // Catch type errors or other unexpected issues
      throw Exception("Unexpected error: $e");
    }
  }

  // --- FETCH SINGLE RESUME ---
  Future<Resume> getResumeById(int id) async {
    try {
      final response = await _dio.get('/resumes/$id/');
      return Resume.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, "Failed to load resume $id");
    }
  }

  // --- CREATE NEW RESUME ---
  Future<Resume> createResume({
    required String title,
    required List<Map<String, dynamic>> canvasData,
  }) async {
    try {
      final response = await _dio.post(
        '/resumes/',
        data: {'title': title, 'canvas_data': canvasData},
      );
      return Resume.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, "Failed to create resume");
    }
  }

  // --- UPDATE EXISTING RESUME ---
  Future<Resume> updateResume({
    required int id,
    String? title,
    List<Map<String, dynamic>>? canvasData,
  }) async {
    try {
      final Map<String, dynamic> payload = {};
      if (title != null) payload['title'] = title;
      if (canvasData != null) payload['canvas_data'] = canvasData;

      final response = await _dio.patch('/resumes/$id/', data: payload);
      return Resume.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, "Failed to update resume");
    }
  }

  // --- DELETE RESUME ---
  Future<void> deleteResume(int id) async {
    try {
      await _dio.delete('/resumes/$id/');
    } on DioException catch (e) {
      throw _handleError(e, "Failed to delete resume");
    }
  }

  // ==========================================
  // 3. CENTRALIZED ERROR HANDLING
  // ==========================================
  Exception _handleError(DioException e, String fallbackMessage) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final serverMessage =
          e.response?.data?['detail'] ?? e.response?.data?['error'];

      if (statusCode == 401) {
        return Exception("Unauthorized. Please log in again.");
      }
      if (serverMessage != null) {
        return Exception("$fallbackMessage: $serverMessage");
      }
      return Exception("$fallbackMessage (Error $statusCode)");
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception("Connection timed out. Check your internet.");
    } else {
      return Exception("Network error. Please check your connection.");
    }
  }
}
