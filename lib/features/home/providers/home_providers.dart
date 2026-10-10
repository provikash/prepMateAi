import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/home_remote_data_source.dart';
import '../data/models/dashboard_model.dart';
import '../data/models/resume_model.dart';
import '../data/models/template_model.dart';
import '../data/repositories/home_repository.dart';
import '../../../config/dio_client.dart';
import '../../../core/cache/cache_store.dart';
import '../../../core/database/app_database.dart';
import '../../../core/offline/local_workspace.dart';
import '../../auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../auth/presentation/state/auth_state.dart';
import '../../resume/data/built_in_templates.dart';

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return HomeRemoteDataSource(dio);
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(
    remote: ref.watch(homeRemoteDataSourceProvider),
    cache: ref.watch(cacheCoordinatorProvider),
  );
});

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardModel>(() {
      return DashboardNotifier();
    });

class DashboardNotifier extends AsyncNotifier<DashboardModel> {
  @override
  Future<DashboardModel> build() async {
    final authState = ref.watch(authViewModelProvider);
    if (authState.status != AuthStatus.authenticated) {
      return DashboardModel.fromJson(const {
        'full_name': 'Guest',
        'message': 'Your resumes are saved on this device.',
      });
    }
    final userId = authState.user!.id;
    return ref
        .watch(homeRepositoryProvider)
        .getDashboard(
          userId: userId,
          onRevalidated: (value) => state = AsyncData(value),
        );
  }

  Future<bool> refresh() async {
    final previous = state.asData?.value;
    if (previous == null) state = const AsyncValue.loading();
    final user = ref.read(authViewModelProvider).user;
    if (user == null) {
      state = AsyncData(
        DashboardModel.fromJson(const {
          'full_name': 'Guest',
          'message': 'Your resumes are saved on this device.',
        }),
      );
      return true;
    }
    try {
      final value = await ref
          .read(homeRepositoryProvider)
          .getDashboard(userId: user.id, forceRefresh: true);
      state = AsyncData(value);
      return true;
    } catch (error, stackTrace) {
      state = previous == null
          ? AsyncError(error, stackTrace)
          : AsyncData(previous);
      return false;
    }
  }
}

final resumeListProvider =
    AsyncNotifierProvider<ResumeListNotifier, List<ResumeModel>>(() {
      return ResumeListNotifier();
    });

final _localResumeListProvider =
    StreamProvider.family<List<ResumeModel>, String>(
      (ref, userId) => ref
          .watch(appDatabaseProvider)
          .watchLocalResumes(userId)
          .map((rows) => rows.map(_localResumeModel).toList(growable: false)),
    );

ResumeModel _localResumeModel(LocalResume row) {
  Map<String, dynamic> payload = const {};
  try {
    final decoded = jsonDecode(row.payload);
    if (decoded is Map) payload = Map<String, dynamic>.from(decoded);
  } catch (_) {
    // Keep a damaged local record visible so the user can retry or remove it.
  }
  final remoteId = row.remoteId?.trim();
  return ResumeModel(
    id: remoteId == null || remoteId.isEmpty ? row.localId : remoteId,
    title: payload['title']?.toString().trim().isNotEmpty == true
        ? payload['title'].toString()
        : 'Untitled Resume',
    thumbnailUrl: '',
    pdfUrl: '',
    syncStatus: row.syncStatus,
    templateId: payload['template_id']?.toString(),
    data: payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'] as Map)
        : const {},
    updatedAt: row.updatedAt,
    isCompleted: payload['draft'] != true && row.syncStatus == 'synced',
  );
}

List<ResumeModel> _mergeResumes(
  List<ResumeModel> remote,
  List<ResumeModel> local,
) {
  final merged = <String, ResumeModel>{
    for (final resume in remote) resume.id: resume,
  };
  for (final resume in local) {
    final serverCopy = merged[resume.id];
    if (serverCopy == null) {
      merged[resume.id] = resume;
    } else if (resume.syncStatus != 'synced') {
      merged[resume.id] = ResumeModel(
        id: resume.id,
        title: resume.title,
        thumbnailUrl: serverCopy.thumbnailUrl,
        pdfUrl: serverCopy.pdfUrl,
        syncStatus: resume.syncStatus,
        templateId: resume.templateId ?? serverCopy.templateId,
        data: resume.data,
        updatedAt: resume.updatedAt,
        isCompleted: serverCopy.isCompleted,
      );
    }
  }
  final values = merged.values.toList();
  values.sort((a, b) {
    final aDate = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });
  return values;
}

class ResumeListNotifier extends AsyncNotifier<List<ResumeModel>> {
  @override
  Future<List<ResumeModel>> build() async {
    final authState = ref.watch(authViewModelProvider);
    final workspace = await ref.watch(localWorkspaceProvider.future);
    final local = await ref.watch(
      _localResumeListProvider(workspace.workspaceId).future,
    );
    if (authState.status != AuthStatus.authenticated ||
        authState.user == null) {
      return local;
    }
    final userId = authState.user!.id;
    try {
      return await ref
          .watch(homeRepositoryProvider)
          .getResumes(
            userId: userId,
            onRevalidated: (value) =>
                state = AsyncData(_mergeResumes(value, local)),
          )
          .then((value) => _mergeResumes(value, local));
    } catch (_) {
      if (local.isNotEmpty) return local;
      rethrow;
    }
  }

  Future<void> refresh() async {
    final previous = state.asData?.value;
    if (previous == null) state = const AsyncValue.loading();
    final workspace = await ref.read(localWorkspaceProvider.future);
    final local = await ref.read(
      _localResumeListProvider(workspace.workspaceId).future,
    );
    final user = ref.read(authViewModelProvider).user;
    if (user == null) {
      state = AsyncData(local);
      return;
    }
    final userId = user.id;
    try {
      final remote = await ref
          .read(homeRepositoryProvider)
          .getResumes(userId: userId, forceRefresh: true);
      state = AsyncData(_mergeResumes(remote, local));
    } catch (error, stackTrace) {
      if (local.isNotEmpty) {
        state = AsyncData(_mergeResumes(previous ?? const [], local));
      } else {
        state = AsyncError(error, stackTrace);
      }
    }
  }
}

final templateListProvider =
    AsyncNotifierProvider<TemplateListNotifier, List<TemplateModel>>(() {
      return TemplateListNotifier();
    });

class TemplateListNotifier extends AsyncNotifier<List<TemplateModel>> {
  static const int catalogLimit = 8;

  List<TemplateModel> _limit(List<TemplateModel> templates) =>
      templates.take(catalogLimit).toList(growable: false);

  @override
  Future<List<TemplateModel>> build() async {
    try {
      final templates = await ref
          .watch(homeRepositoryProvider)
          .getTemplates(
            onRevalidated: (value) =>
                state = AsyncData(_limit(mergeBuiltInTemplates(value))),
          );
      return _limit(mergeBuiltInTemplates(templates));
    } catch (_) {
      return _limit(builtInTemplates);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final templates = await ref
          .read(homeRepositoryProvider)
          .getTemplates(forceRefresh: true);
      state = AsyncData(_limit(mergeBuiltInTemplates(templates)));
    } catch (_) {
      state = AsyncData(_limit(builtInTemplates));
    }
  }
}

final bottomNavProvider = StateProvider<int>((ref) => 0);
