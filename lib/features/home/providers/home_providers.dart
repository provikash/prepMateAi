import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/home_remote_data_source.dart';
import '../data/models/dashboard_model.dart';
import '../data/models/resume_model.dart';
import '../data/models/template_model.dart';
import '../data/repositories/home_repository.dart';
import '../../../config/dio_client.dart';
import '../../../core/cache/cache_store.dart';
import '../../../core/offline/offline_status.dart';
import '../../auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../auth/presentation/state/auth_state.dart';

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
    // Ensure authenticated
    final authState = ref.watch(authViewModelProvider);
    if (authState.status != AuthStatus.authenticated) {
      throw Exception('User not authenticated');
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
    try {
      final value = await ref
          .read(homeRepositoryProvider)
          .getDashboard(
            userId: ref.read(authViewModelProvider).user!.id,
            forceRefresh: true,
          );
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

final resumeListStatusProvider = StateProvider<OfflineStatus>(
  (ref) => const OfflineStatus(),
);

final resumeListProvider =
    StreamNotifierProvider<ResumeListNotifier, List<ResumeModel>>(
      ResumeListNotifier.new,
    );

class ResumeListNotifier extends StreamNotifier<List<ResumeModel>> {
  @override
  Stream<List<ResumeModel>> build() {
    final authState = ref.watch(authViewModelProvider);
    if (authState.status != AuthStatus.authenticated) {
      throw Exception('User not authenticated');
    }
    final userId = authState.user!.id;
    final database = ref.watch(appDatabaseProvider);
    final controller = StreamController<List<ResumeModel>>();
    var remote = <ResumeModel>[];
    var local = <ResumeModel>[];

    void emit() {
      final localRemoteIds = local.map((item) => item.id).toSet();
      controller.add([
        ...local,
        ...remote.where((item) => !localRemoteIds.contains(item.id)),
      ]);
    }

    final remoteSubscription = ref
        .watch(homeRepositoryProvider)
        .watchResumes(userId)
        .listen((cached) {
          ref.read(resumeListStatusProvider.notifier).state = OfflineStatus(
            isOffline: cached.isOffline,
            isStale: cached.isStale,
            updatedAt: cached.updatedAt,
          );
          remote = cached.value;
          emit();
        }, onError: controller.addError);
    final localSubscription = database.watchLocalResumes(userId).listen((rows) {
      local = rows.map((row) {
        final payload = Map<String, dynamic>.from(
          jsonDecode(row.payload) as Map,
        );
        return ResumeModel(
          id: row.remoteId ?? row.localId,
          title: payload['title']?.toString() ?? 'Untitled Resume',
          thumbnailUrl: '',
          pdfUrl: '',
          syncStatus: row.syncStatus,
        );
      }).toList();
      emit();
    }, onError: controller.addError);
    ref.onDispose(() async {
      await remoteSubscription.cancel();
      await localSubscription.cancel();
      await controller.close();
    });
    return controller.stream;
  }

  Future<void> refresh() async {
    final status = ref.read(resumeListStatusProvider);
    ref.read(resumeListStatusProvider.notifier).state = status.copyWith(
      isRefreshing: true,
    );
    try {
      await ref
          .read(homeRepositoryProvider)
          .refreshResumes(ref.read(authViewModelProvider).user!.id);
    } catch (error, stackTrace) {
      ref.read(resumeListStatusProvider.notifier).state = status.copyWith(
        isOffline: true,
        isStale: true,
        isRefreshing: false,
      );
      if (!state.hasValue) state = AsyncError(error, stackTrace);
    }
  }
}

final templateListStatusProvider = StateProvider<OfflineStatus>(
  (ref) => const OfflineStatus(),
);

final templateListProvider =
    StreamNotifierProvider<TemplateListNotifier, List<TemplateModel>>(
      TemplateListNotifier.new,
    );

class TemplateListNotifier extends StreamNotifier<List<TemplateModel>> {
  @override
  Stream<List<TemplateModel>> build() {
    return ref.watch(homeRepositoryProvider).watchTemplates().map((cached) {
      ref.read(templateListStatusProvider.notifier).state = OfflineStatus(
        isOffline: cached.isOffline,
        isStale: cached.isStale,
        updatedAt: cached.updatedAt,
      );
      return cached.value;
    });
  }

  Future<void> refresh() async {
    final status = ref.read(templateListStatusProvider);
    ref.read(templateListStatusProvider.notifier).state = status.copyWith(
      isRefreshing: true,
    );
    try {
      await ref.read(homeRepositoryProvider).refreshTemplates();
    } catch (error, stackTrace) {
      ref.read(templateListStatusProvider.notifier).state = status.copyWith(
        isOffline: true,
        isStale: true,
        isRefreshing: false,
      );
      if (!state.hasValue) state = AsyncError(error, stackTrace);
    }
  }
}

final bottomNavProvider = StateProvider<int>((ref) => 0);
