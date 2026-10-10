import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dio_client.dart';
import '../../../../core/cache/cache_store.dart';
import '../../../../core/cache/pdf_cache_store.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/offline/local_workspace.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../../home/providers/home_providers.dart' as home;
import '../../../ai_credits/presentation/providers/ai_credits_provider.dart';
import '../../data/datasources/resume_remote_data_source.dart';
import '../../data/models/created_resume_model.dart';
import '../../data/models/resume_model.dart';
import '../../data/models/template_detail_model.dart';
import '../../data/repositories/resume_repository_impl.dart';
import '../../domain/repositories/resume_repository.dart';

final resumeRemoteDataSourceProvider = Provider<ResumeRemoteDataSource>((ref) {
  return ResumeRemoteDataSource(dio: ref.watch(dioProvider));
});

final resumeRepositoryProvider = Provider<ResumeRepository>((ref) {
  return ResumeRepositoryImpl(
    ref.watch(resumeRemoteDataSourceProvider),
    cache: ref.watch(cacheCoordinatorProvider),
    pdfCache: ref.watch(pdfCacheStoreProvider),
    userId: () => ref.read(authViewModelProvider).user?.id,
    workspace: () => ref.read(localWorkspaceProvider.future),
    database: ref.watch(appDatabaseProvider),
    syncEngine: ref.watch(syncEngineProvider),
  );
});

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(
    database: ref.watch(appDatabaseProvider),
    resumes: ref.watch(resumeRemoteDataSourceProvider),
    dio: ref.watch(dioProvider),
  ),
);

class SyncUiState {
  const SyncUiState({this.running = false, this.lastSyncedAt, this.error});
  final bool running;
  final DateTime? lastSyncedAt;
  final String? error;
}

class SyncController extends StateNotifier<SyncUiState> {
  SyncController(this.ref) : super(const SyncUiState());
  final Ref ref;

  Future<SyncRunResult> sync({
    SyncRunSource source = SyncRunSource.manual,
  }) async {
    final accountId = ref.read(authViewModelProvider).user?.id;
    if (accountId == null) {
      return const SyncRunResult(
        processed: 0,
        failed: 0,
        retryScheduled: false,
      );
    }
    if (state.running) {
      return ref.read(syncEngineProvider).run(source: source);
    }
    state = SyncUiState(running: true, lastSyncedAt: state.lastSyncedAt);
    try {
      final workspace = await ref.read(localWorkspaceProvider.future);
      await ref
          .read(appDatabaseProvider)
          .queueWorkspaceResumesForSync(
            workspaceId: workspace.workspaceId,
            accountId: accountId,
          );
      final result = await ref.read(syncEngineProvider).run(source: source);
      await ref
          .read(home.homeRepositoryProvider)
          .invalidateResumeData(accountId);
      await ref
          .read(cacheStoreProvider)
          .remove(
            CacheKeyFactory.user(accountId, 'builder_resumes', const {
              'page': 1,
            }),
          );
      state = SyncUiState(
        lastSyncedAt: DateTime.now(),
        error: result.failed == 0
            ? null
            : '${result.failed} change(s) need attention or a retry.',
      );
      ref.invalidate(home.resumeListProvider);
      await ref.read(aiCreditsProvider.notifier).refreshAfterAiOperation();
      return result;
    } catch (error) {
      state = SyncUiState(
        lastSyncedAt: state.lastSyncedAt,
        error: 'Sync could not reach the server.',
      );
      rethrow;
    }
  }
}

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncUiState>(
      (ref) => SyncController(ref),
    );

final pendingMutationCountProvider = StreamProvider<int>((ref) {
  final userId = ref.watch(authViewModelProvider).user?.id;
  if (userId == null) return Stream.value(0);
  final database = ref.watch(appDatabaseProvider);
  return (database.select(database.mutationOutbox)
        ..where((row) => row.userId.equals(userId)))
      .watch()
      .map((rows) => rows.length);
});

final templateDetailProvider =
    FutureProvider.family<TemplateDetailModel, String>((ref, templateId) {
      return ref.watch(resumeRepositoryProvider).getTemplateDetail(templateId);
    });

final templateProvider = templateDetailProvider;

final templatesListProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>(
  (ref) => ref
      .watch(home.templateListProvider)
      .whenData(
        (templates) => templates.map((template) => template.toJson()).toList(),
      ),
);

class CreateResumeState {
  final bool isLoading;
  final CreatedResumeModel? data;
  final String? error;

  const CreateResumeState({this.isLoading = false, this.data, this.error});

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
    required String title,
    required Map<String, dynamic> formData,
  }) async {
    state = const CreateResumeState(isLoading: true);
    try {
      final created = await repository.createResume(
        templateId: templateId,
        title: title,
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

final createResumeProvider =
    StateNotifierProvider<CreateResumeNotifier, CreateResumeState>((ref) {
      return CreateResumeNotifier(ref.watch(resumeRepositoryProvider));
    });

final resumeProvider = createResumeProvider;

final pdfViewerProvider = FutureProvider.autoDispose.family<Uint8List, String>((
  ref,
  resumeId,
) {
  return ref.watch(resumeRepositoryProvider).getResumePdfBytes(resumeId);
});

final storedResumesProvider = Provider<AsyncValue<List<ResumeModel>>>((ref) {
  return ref
      .watch(home.resumeListProvider)
      .whenData(
        (resumes) => resumes
            .map(
              (resume) => ResumeModel(
                id: resume.id,
                title: resume.title,
                pdfUrl: resume.pdfUrl,
              ),
            )
            .toList(),
      );
});
