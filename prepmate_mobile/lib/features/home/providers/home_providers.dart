import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/home_remote_data_source.dart';
import '../data/models/dashboard_model.dart';
import '../data/models/resume_model.dart';
import '../data/models/template_model.dart';
import '../../../config/dio_client.dart';
import '../../auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../auth/presentation/state/auth_state.dart';

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return HomeRemoteDataSource(dio);
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
    return ref.watch(homeRemoteDataSourceProvider).getDashboard();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(homeRemoteDataSourceProvider).getDashboard(),
    );
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
    return ref.watch(homeRemoteDataSourceProvider).getResumes();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(homeRemoteDataSourceProvider).getResumes(),
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
    return ref.watch(homeRemoteDataSourceProvider).getTemplates();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(homeRemoteDataSourceProvider).getTemplates(),
    );
  }
}

final bottomNavProvider = StateProvider<int>((ref) => 0);
