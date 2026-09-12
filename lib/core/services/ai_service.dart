import 'package:dio/dio.dart';

class AIService {
  final Dio dio;

  AIService(this.dio);

  Future<Map<String, dynamic>> submit(String action, Map<String, dynamic> payload) async {
    // action values: generate-summary, improve-section, suggest-skills, generate-bullets
    final endpoint = '/ai/$action/';
    final response = await dio.post(endpoint, data: payload);
    return Map<String, dynamic>.from(response.data as Map<String, dynamic>);
  }
}
