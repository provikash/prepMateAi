import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'profile_state.dart';
import 'package:prepmate_mobile/features/profile/domain/repositories/profile_repository.dart';

class ProfileViewModel extends StateNotifier<ProfileState> {
  final ProfileRepository repository;

  ProfileViewModel(this.repository) : super(ProfileState());

  /// Load Profile
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await repository.getProfile();

      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: _handleError(e), isLoading: false);
    }
  }

  /// Update Profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedUser = await repository.updateProfile(data);

      state = state.copyWith(user: updatedUser, isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(error: _handleError(e), isLoading: false);
      return false;
    }
  }

  /// Upload Profile Image
  Future<bool> uploadProfileImage(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedUser = await repository.uploadProfileImage(filePath);

      state = state.copyWith(user: updatedUser, isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(error: _handleError(e), isLoading: false);
      return false;
    }
  }

  /// Refresh Profile
  Future<void> refresh() async {
    await loadProfile();
  }

  /// Logout
  Future<void> logout() async {
    await repository.logout();
    state = ProfileState();
  }

  /// 🔥 Centralized Error Handler
  String _handleError(dynamic error) {
    if (error is DioException) {
      return error.response?.data['message'] ?? "Network error occurred";
    }
    return "Something went wrong";
  }
}
