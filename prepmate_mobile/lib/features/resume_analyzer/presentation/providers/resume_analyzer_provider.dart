import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/dio_client.dart';
import '../../data/datasources/resume_analyzer_remote_datasource.dart';
import '../../data/models/resume_analysis_model.dart';
import '../../data/models/resume_model.dart';

final resumeAnalyzerDataSourceProvider = Provider<ResumeAnalyzerRemoteDataSource>((ref) {
  return ResumeAnalyzerRemoteDataSource(ref.watch(dioProvider));
});

final resumeListProvider = FutureProvider<List<ResumeModel>>((ref) async {
  return ref.watch(resumeAnalyzerDataSourceProvider).getResumes();
});

class ResumeAnalyzerNotifier extends StateNotifier<AsyncValue<ResumeAnalysisModel?>> {
  final ResumeAnalyzerRemoteDataSource _dataSource;

  ResumeAnalyzerNotifier(this._dataSource) : super(const AsyncValue.data(null));

  Future<void> analyzeResume({
    required String jobRole,
    String? resumeId,
    File? uploadedFile,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _dataSource.analyzeResume(
        jobRole: jobRole,
        resumeId: resumeId,
        uploadedFile: uploadedFile,
      );
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final resumeAnalyzerProvider = StateNotifierProvider<ResumeAnalyzerNotifier, AsyncValue<ResumeAnalysisModel?>>((ref) {
  return ResumeAnalyzerNotifier(ref.watch(resumeAnalyzerDataSourceProvider));
});
