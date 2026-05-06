import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/created_resume_model.dart';
import '../models/resume_model.dart';
import '../models/template_detail_model.dart';

class ResumeRemoteDataSource {
  final Dio dio;
  final FlutterSecureStorage secureStorage;

  ResumeRemoteDataSource({required this.dio, required this.secureStorage});

  Future<Options> _authorizedOptions() async {
    final token = await secureStorage.read(key: 'access_token');
    final headers = <String, dynamic>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return Options(headers: headers);
  }

  String _normalizeDioError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.error is SocketException) {
        return 'No internet connection. Please check your network and try again.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Request timed out. Please try again.';
      }
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        if (data['detail'] != null) {
          return data['detail'].toString();
        }
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
      return error.message ?? 'Network error';
    }
    return error.toString();
  }

  Future<TemplateDetailModel> getTemplateDetail(String id) async {
    try {
      final response = await dio.get(
        'templates/$id/',
        options: await _authorizedOptions(),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return TemplateDetailModel.fromJson(data);
      }
      if (data is List && data.isNotEmpty && data[0] is Map<String, dynamic>) {
        // sometimes backend returns a list — pick the first item
        return TemplateDetailModel.fromJson(data[0] as Map<String, dynamic>);
      }
      throw Exception('Unexpected template format: ${data.runtimeType}');
    } catch (error) {
      throw Exception(
        'Failed to load template detail: ${_normalizeDioError(error)}',
      );
    }
  }

  Future<CreatedResumeModel> createResume({
    required String templateId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final options = await _authorizedOptions();
      if (options.headers?['Authorization'] == null) {
        throw Exception('Missing auth token. Please sign in again.');
      }

      final response = await dio.post(
        'resumes/',
        data: {
          'template_id': templateId,
          'data': data,
        },
        options: options,
      );
      return CreatedResumeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      debugPrint('Resume save failed: ${error.response?.data}');
      throw Exception('Failed to create resume: ${_normalizeDioError(error)}');
    } catch (error) {
      debugPrint('Resume save failed: $error');
      throw Exception('Failed to create resume: ${_normalizeDioError(error)}');
    }
  }

  Future<String> getResumePdfUrl(String id) async {
    final base = dio.options.baseUrl;
    return '$base/resumes/$id/export/'.replaceAll('//resumes', '/resumes');
  }

  Future<Uint8List> getResumePdfBytes(String id) async {
    try {
      final response = await dio.get<List<int>>(
        'resumes/$id/export/',
        options: Options(
          headers: (await _authorizedOptions()).headers,
          responseType: ResponseType.bytes,
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Empty PDF response');
      }
      return Uint8List.fromList(bytes);
    } catch (error) {
      throw Exception('Failed to load PDF: ${_normalizeDioError(error)}');
    }
  }

  Future<Uint8List> downloadPdf(String id) {
    return getResumePdfBytes(id);
  }

  Future<List<ResumeModel>> getResumes() async {
    try {
      final response = await dio.get(
        'resumes/',
        options: await _authorizedOptions(),
      );
      final payload = response.data;
      final list = payload is Map<String, dynamic>
          ? (payload['results'] as List?) ?? const []
          : payload as List? ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ResumeModel.fromJson)
          .toList();
    } catch (error) {
      throw Exception('Failed to load resumes: ${_normalizeDioError(error)}');
    }
  }

  Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final response = await dio.get('templates/');
      final payload = response.data;
      final list = payload is Map<String, dynamic>
          ? (payload['results'] as List?) ?? const []
          : payload as List? ?? const [];
      return list.whereType<Map<String, dynamic>>().map((e) => e).toList();
    } catch (error) {
      throw Exception('Failed to load templates: ${_normalizeDioError(error)}');
    }
  }
}
