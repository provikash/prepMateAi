

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:prepmate_mobile/features/resume/data/models/resume_model.dart';

import '../../../config/dio_client.dart';


final resumeApiProvider = Provider<ResumeApi>((ref) {
  final dio = ref.watch(dioProvider);
  return ResumeApi(dio);
});

class ResumeApi {
  final Dio dio;

  ResumeApi(this.dio);

  Future<List<Resume>> getResume() async {
    final res = await dio.get("resumes/");
    return (res.data as List).map((e) => Resume.fromJson(e)).toList();
  }

  Future<Resume> createResumeWithTemplate( String template, String title, Map<String,dynamic> content) async {
    final res = await dio.post("resumes/", data: {"title": "Untitled Resume",
    "template": template,
      "content": content});
    return Resume.fromJson(res.data);
  }

  Future<void> updateResume(int id, Map data) async {
    await dio.put("/api/resume/$id/", data: data);
  }

  Future<void> deleteResume(int id) async {
    await dio.put("api/resume/delete/$id/");
  }
}
