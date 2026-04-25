import 'package:dio/dio.dart';
import '../models/dashboard_model.dart';
import '../models/resume_model.dart';
import '../models/template_model.dart';

class HomeRemoteDataSource {
  final Dio dio;

  HomeRemoteDataSource(this.dio);

  Future<DashboardModel> getDashboard() async {
    try {
      final response = await dio.get('v1/dashboard/');
      return DashboardModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ResumeModel>> getResumes() async {
    try {
      final response = await dio.get('v1/resumes/');
      final List results = response.data['results'] ?? [];
      return results.map((e) => ResumeModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TemplateModel>> getTemplates() async {
    try {
      final response = await dio.get('v1/templates/');
      final List results = response.data['results'] ?? [];
      return results.map((e) => TemplateModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
