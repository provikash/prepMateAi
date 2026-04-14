import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../config/dio_client.dart';
import '../data/homestate.dart';

class HomeDashboardNotifier extends AsyncNotifier<PrepMateHomeState> {
  @override
  Future<PrepMateHomeState> build() async {
    final authState = ref.watch(authNotifierProvider);

    if (authState.status != AuthStatus.authenticated) {
      throw Exception('User is not authenticated');
    }

    final dio = ref.watch(dioProvider);
    // authState.user.id is a String, but based on your resume API it might be an int in some places.
    // Ensure this matches your backend requirements.
    return _fetchDashboardData(dio, authState.User.id.toString());
  }

  Future<PrepMateHomeState> _fetchDashboardData(Dio dio, String userId) async {
    try {
      final response = await dio.get('/api/users/$userId/dashboard/');
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
  // 1. Get your configured Dio client
  final dio = ref.watch(dioProvider);

  try {
    // 2. Make the request to your Django backend
    // Replace with your actual user profile endpoint
    final response = await dio.get('/api/users/me/profile/');

    // 3. Return the JSON data
    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    // 4. Handle errors gracefully so the UI can react
    if (e.response?.statusCode == 404) {
      throw Exception('User profile not found.');
    }
    throw Exception('Failed to load user data: ${e.message}');
  }
});
