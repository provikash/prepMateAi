import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/home_remote_data_source.dart';
import '../data/models/dashboard_model.dart';
import '../data/models/resume_model.dart';
import '../data/models/template_model.dart';
import '../data/repositories/home_repository.dart';
import '../../../config/dio_client.dart';
import '../../../core/cache/cache_store.dart';
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

final resumeListProvider =
    AsyncNotifierProvider<ResumeListNotifier, List<ResumeModel>>(() {
      return ResumeListNotifier();
    });

class ResumeListNotifier extends AsyncNotifier<List<ResumeModel>> {
  @override
  Future<List<ResumeModel>> build() async {
    final authState = ref.watch(authViewModelProvider);
    if (authState.status != AuthStatus.authenticated) {
      throw Exception('User not authenticated');
    }
    final userId = authState.user!.id;
    return ref
        .watch(homeRepositoryProvider)
        .getResumes(
          userId: userId,
          onRevalidated: (value) => state = AsyncData(value),
        );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(homeRepositoryProvider)
          .getResumes(
            userId: ref.read(authViewModelProvider).user!.id,
            forceRefresh: true,
          ),
    );
  }
}

final templateListProvider =
    AsyncNotifierProvider<TemplateListNotifier, List<TemplateModel>>(() {
      return TemplateListNotifier();
    });

class TemplateListNotifier extends AsyncNotifier<List<TemplateModel>> {
  @override
  Future<List<TemplateModel>> build() async {
    return ref
        .watch(homeRepositoryProvider)
        .getTemplates(onRevalidated: (value) => state = AsyncData(value));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(homeRepositoryProvider).getTemplates(forceRefresh: true),
    );
  }
}

final bottomNavProvider = StateProvider<int>((ref) => 0);
