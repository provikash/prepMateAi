import 'dart:io';

import 'package:dio/dio.dart';

import '../models/dashboard_model.dart';
import '../models/resume_model.dart';
import '../models/resume_detail_model.dart';
import '../models/template_model.dart';
import '../models/template_detail_model.dart';

class HomeRemoteDataSource {
  final Dio dio;

  HomeRemoteDataSource(this.dio);

  Future<DashboardModel> getDashboard() async {
    try {
      final response = await dio.get('dashboard/');
      final body = response.data;
      if (body is! Map) {
        throw const HomeRequestException('Dashboard data could not be loaded.');
      }
      final mapped = Map<String, dynamic>.from(body);
      final data = mapped['data'];
      return DashboardModel.fromJson(
        data is Map ? Map<String, dynamic>.from(data) : mapped,
      );
    } on HomeRequestException {
      rethrow;
    } on DioException catch (error) {
      throw HomeRequestException.fromDio(error);
    } catch (_) {
      throw const HomeRequestException('Dashboard data could not be loaded.');
    }
  }

  Future<List<ResumeModel>> getResumes() async {
    try {
      final response = await dio.get('resumes/');
      final List results = response.data['results'] ?? [];
      return results.map((e) => ResumeModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TemplateModel>> getTemplates() async {
    try {
      final response = await dio.get('templates/');
      final List results = response.data['results'] ?? [];
      return results.map((e) => TemplateModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<ResumeDetailModel> getResumeById(String resumeId) async {
    try {
      final response = await dio.get('resumes/$resumeId/');
      return ResumeDetailModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<TemplateDetailModel> getTemplateById(String templateId) async {
    try {
      final response = await dio.get('templates/$templateId/');
      return TemplateDetailModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<ResumeDetailModel> createResumeFromTemplate({
    required String templateId,
    required String title,
    required Map<String, dynamic> data,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await dio.post(
        'resumes/',
        data: {
          'template_id': templateId,
          'title': title,
          'data': data,
          'metadata': metadata ?? {},
        },
      );
      return ResumeDetailModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<ResumeDetailModel> updateResume({
    required String resumeId,
    required String title,
    required Map<String, dynamic> data,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await dio.patch(
        'resumes/$resumeId/',
        data: {'title': title, 'data': data, 'metadata': metadata ?? {}},
      );
      return ResumeDetailModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteResume(String resumeId) async {
    try {
      await dio.delete('resumes/$resumeId/');
    } catch (e) {
      rethrow;
    }
  }
}

class HomeRequestException implements Exception {
  const HomeRequestException(this.message);

  final String message;

  factory HomeRequestException.fromDio(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException) {
      return const HomeRequestException(
        'The server could not be reached. Check your connection and retry.',
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const HomeRequestException(
        'The dashboard request timed out. Please retry.',
      );
    }
    return HomeRequestException(switch (error.response?.statusCode) {
      401 => 'Your session expired. Please sign in again.',
      403 => 'Dashboard access is not available for this account.',
      404 => 'Dashboard data could not be found.',
      429 => 'Too many requests. Please wait and retry.',
      500 => 'Dashboard data could not be loaded. Please retry.',
      _ => 'Dashboard data could not be loaded.',
    });
  }

  @override
  String toString() => message;
}
