import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepmate_mobile/config/dio_client.dart';
import '../data/models/resume_template.dart';

final templateListProvider = FutureProvider<List<ResumeTemplate>>((ref) async {
  final dio = ref.watch(dioProvider);

  // Updated to match your paginated endpoint: /api/v1/templates/
  final response = await dio.get('v1/templates/');

  // The backend returns a paginated response with a 'results' key
  final List<dynamic> results = response.data['results'];

  return results.map((json) => ResumeTemplate.fromJson(json)).toList();
});
