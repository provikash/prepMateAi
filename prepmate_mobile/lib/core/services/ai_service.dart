import 'dart:async';

import 'package:dio/dio.dart';

class AIService {
  final Dio dio;

  AIService(this.dio);

  Future<String> submit(String action, Map<String, dynamic> payload) async {
    // action values: generate-summary, improve-section, suggest-skills, generate-bullets
    final endpoint = '/ai/$action/';
    final resp = await dio.post(endpoint, data: payload);
    return resp.data['task_id'] as String;
  }

  Future<Map<String, dynamic>> getTask(String taskId) async {
    final resp = await dio.get('/ai/tasks/$taskId/');
    return Map<String, dynamic>.from(resp.data as Map);
  }
}
