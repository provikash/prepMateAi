import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/dio_client.dart';
import '../../data/models/resume_analysis_model.dart';
import '../../data/repositories/resume_analyzer_repository_impl.dart';
import '../../domain/repositories/resume_analyzer_repository.dart';

final resumeAnalyzerRepositoryProvider = Provider<ResumeAnalyzerRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ResumeAnalyzerRepositoryImpl(dio);
});

// State classes
class AsyncState<T> {
  final bool isLoading;
  final T? data;
  final String? errorMessage;

  AsyncState({this.isLoading = false, this.data, this.errorMessage});

  AsyncState<T> copyWith({bool? isLoading, T? data, String? errorMessage}) {
    return AsyncState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// 1. analyzeProvider
final analyzeProvider = StateNotifierProvider<AnalyzeNotifier, AsyncState<ResumeAnalysisModel>>((ref) {
  return AnalyzeNotifier(ref.watch(resumeAnalyzerRepositoryProvider));
});

class AnalyzeNotifier extends StateNotifier<AsyncState<ResumeAnalysisModel>> {
  final ResumeAnalyzerRepository _repository;
  AnalyzeNotifier(this._repository) : super(AsyncState());

  Future<void> analyze({String? resumeId, File? file, required String jobRole}) async {
    // Basic validation
    if (jobRole.isEmpty || jobRole.length > 120) {
      state = AsyncState(errorMessage: "Job role must be 1-120 characters");
      return;
    }
    if (resumeId == null && file == null) {
      state = AsyncState(errorMessage: "Please upload a file or select a resume");
      return;
    }
    if (file != null) {
      if (!file.path.toLowerCase().endsWith('.pdf')) {
        state = AsyncState(errorMessage: "Only PDF files are allowed");
        return;
      }
      final size = await file.length();
      if (size > 10 * 1024 * 1024) {
        state = AsyncState(errorMessage: "File size must be less than 10MB");
        return;
      }
    }

    state = AsyncState(isLoading: true);
    try {
      final result = await _repository.analyzeResume(
        resumeId: resumeId,
        file: file,
        jobRole: jobRole,
      );
      state = AsyncState(data: result);
    } catch (e) {
      state = AsyncState(errorMessage: e.toString());
    }
  }
}

// 2. historyProvider
final historyProvider = AsyncNotifierProvider<HistoryNotifier, List<ResumeAnalysisModel>>(() {
  return HistoryNotifier();
});

class HistoryNotifier extends AsyncNotifier<List<ResumeAnalysisModel>> {
  @override
  Future<List<ResumeAnalysisModel>> build() async {
    return ref.read(resumeAnalyzerRepositoryProvider).getHistory();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(resumeAnalyzerRepositoryProvider).getHistory());
  }
}

// 3. analysisDetailProvider
final analysisDetailProvider = StateNotifierProvider.family<DetailNotifier, AsyncState<ResumeAnalysisModel>, String>((ref, id) {
  return DetailNotifier(ref.watch(resumeAnalyzerRepositoryProvider), id);
});

class DetailNotifier extends StateNotifier<AsyncState<ResumeAnalysisModel>> {
  final ResumeAnalyzerRepository _repository;
  final String id;
  DetailNotifier(this._repository, this.id) : super(AsyncState()) {
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    state = AsyncState(isLoading: true);
    try {
      final result = await _repository.getAnalysisDetail(id);
      state = AsyncState(data: result);
    } catch (e) {
      state = AsyncState(errorMessage: e.toString());
    }
  }
}
