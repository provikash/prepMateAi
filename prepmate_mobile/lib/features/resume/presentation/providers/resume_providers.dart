import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dio_client.dart';
import '../../data/datasources/resume_remote_data_source.dart';
import '../../data/models/created_resume_model.dart';
import '../../data/models/resume_model.dart';
import '../../data/models/template_detail_model.dart';
import '../../data/repositories/resume_repository_impl.dart';
import '../../domain/repositories/resume_repository.dart';

final resumeRemoteDataSourceProvider = Provider<ResumeRemoteDataSource>((ref) {
  return ResumeRemoteDataSource(
    dio: ref.watch(dioProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

final resumeRepositoryProvider = Provider<ResumeRepository>((ref) {
  return ResumeRepositoryImpl(ref.watch(resumeRemoteDataSourceProvider));
});

final templateDetailProvider = FutureProvider.family<TemplateDetailModel, String>((ref, templateId) {
  return ref.watch(resumeRepositoryProvider).getTemplateDetail(templateId);
});

final templateProvider = templateDetailProvider;

final templatesListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(resumeRepositoryProvider).getTemplates();
});

class CreateResumeState {
  final bool isLoading;
  final CreatedResumeModel? data;
  final String? error;

  const CreateResumeState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  CreateResumeState copyWith({
    bool? isLoading,
    CreatedResumeModel? data,
    String? error,
  }) {
    return CreateResumeState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
    );
  }
}

class CreateResumeNotifier extends StateNotifier<CreateResumeState> {
  final ResumeRepository repository;

  CreateResumeNotifier(this.repository) : super(const CreateResumeState());

  Future<CreatedResumeModel?> submit({
    required String templateId,
    required Map<String, dynamic> formData,
  }) async {
    state = const CreateResumeState(isLoading: true);
    try {
      final created = await repository.createResume(
        templateId: templateId,
        data: formData,
      );
      state = CreateResumeState(data: created);
      return created;
    } catch (error) {
      state = CreateResumeState(error: error.toString());
      return null;
    }
  }
}

final createResumeProvider = StateNotifierProvider<CreateResumeNotifier, CreateResumeState>((ref) {
  return CreateResumeNotifier(ref.watch(resumeRepositoryProvider));
});

final resumeProvider = createResumeProvider;

final pdfViewerProvider = FutureProvider.family<Uint8List, String>((ref, resumeId) {
  return ref.watch(resumeRepositoryProvider).getResumePdfBytes(resumeId);
});

final storedResumesProvider = FutureProvider<List<ResumeModel>>((ref) {
  return ref.watch(resumeRepositoryProvider).getResumes();
});
