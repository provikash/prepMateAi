import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepmate_mobile/config/dio_client.dart';
import '../data/models/resume_template.dart';

final templateListProvider = FutureProvider<List<ResumeTemplate>>((ref) async {
  final dio = ref.watch(dioProvider);

  final response = await dio.get('/templates');

  return (response.data as List)
      .map((json) => ResumeTemplate.fromJson(json))
      .toList();
});
