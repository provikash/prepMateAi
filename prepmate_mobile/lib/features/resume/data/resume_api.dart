import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/dio_client.dart';
import 'models/resume.dart';

// ==========================================
// 1. THE API PROVIDER
// ==========================================
// Assume you have a global dioProvider setup in your core network folder.
// If not, you can replace `ref.read(dioProvider)` with your standard Dio setup.
final resumeApiProvider = Provider<ResumeApi>((ref) {
  // We inject the configured Dio instance (which should already have your
  // base URL and Auth tokens) into the API class.
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

      // Transform the raw JSON list into a list of Dart 'Resume' objects
      final List<dynamic> data = response.data;
      return data.map((json) => Resume.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e, "Failed to fetch resumes");
    }
  }

  // --- FETCH SINGLE RESUME (Optional, if needed for deep linking) ---
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
      // Build payload dynamically so we only send what needs updating
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
  // This ensures your UI gets clean, readable error messages instead of
  // massive stack traces from Dio.
  Exception _handleError(DioException e, String fallbackMessage) {
    if (e.response != null) {
      // The server received the request and returned an error (e.g., 400, 401, 500)
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
      // Something happened in setting up or sending the request
      return Exception("Network error. Please check your connection.");
    }
  }
}
