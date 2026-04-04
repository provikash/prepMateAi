import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:prepmate_mobile/features/resume/data/models/resume_model.dart';

import '../../../config/dio_client.dart';
import '../../../core/services/storage.dart';

import 'package:http/http.dart' as http;

final resumeApiProvider = Provider<ResumeApi>((ref) {
  final dio = ref.watch(dioProvider);
  return ResumeApi(dio);
});

class ResumeApi {
  final Dio dio;

  ResumeApi(this.dio);

  static const String baseUrl = "http://10.145.242:8000/api";

  Future<List<Resume>> getResume() async {
    final res = await dio.get("resumes/");
    return (res.data as List).map((e) => Resume.fromJson(e)).toList();
  }

  static Future createResume() async {
    final token = await TokenService.getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/resumes/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"title": "Untitled Resume"}),
    );

    return jsonDecode(response.body);
  }

  Future<void> updateResume(int id, Map data) async {
    await dio.put("/api/resume/$id/", data: data);
  }

  Future<void> deleteResume(int id) async {
    await dio.put("api/resume/delete/$id/");
  }
}
