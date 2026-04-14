import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../config/dio_client.dart';
import '../../auth/presentation/state/auth_state.dart';
import '../../auth/presentation/viewmodel/auth_viewmodel.dart';
import '../data/homestate.dart';

class HomeDashboardNotifier extends AsyncNotifier<PrepMateHomeState> {
  @override
  Future<PrepMateHomeState> build() async {
    final authState = ref.watch(authViewModelProvider);

    if (authState.status != AuthStatus.authenticated ||
        authState.user == null) {
      throw Exception('User is not authenticated');
    }

    final dio = ref.watch(dioProvider);
    return _fetchDashboardData(dio, authState.user!.id);
  }

  Future<PrepMateHomeState> _fetchDashboardData(Dio dio, String userId) async {
    try {
      final response = await dio.get('users/$userId/dashboard/');
      final data = response.data;

      return PrepMateHomeState(
        userName: data['user_name'] ?? 'User',
        role: data['role'] ?? 'Designer',
        progress: data['progress_value']?.toDouble() ?? 0.0,
        aiSuggestion: data['ai_suggestion'] ?? 'Keep learning!',
        progressStatus: data['status'] ?? 'Draft',
      );
    } on DioException catch (e) {
      throw Exception('Failed to load dashboard: ${e.message}');
    }
  }

  Future<void> refreshDashboard() async {
    state = const AsyncLoading();
    ref.invalidateSelf();
  }
}

final homeDashboardProvider =
    AsyncNotifierProvider<HomeDashboardNotifier, PrepMateHomeState>(
      HomeDashboardNotifier.new,
    );

final bottomNavProvider = StateProvider<int>((ref) => 0);

final userDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);

  try {
    final response = await dio.get('users/me/profile/');
    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) {
      throw Exception('User profile not found.');
    }
    throw Exception('Failed to load user data: ${e.message}');
  }
});
