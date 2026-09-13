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
      return DashboardModel.fromJson(response.data);
    } catch (e) {
      rethrow;
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
