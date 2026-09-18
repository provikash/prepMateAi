import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'profile_state.dart';
import 'package:prepmate_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:prepmate_mobile/features/auth/data/models/user_model.dart';
import '../../data/datasources/profile_remote_data_source.dart';

class ProfileViewModel extends StateNotifier<ProfileState> {
  final ProfileRepository repository;

  ProfileViewModel(this.repository) : super(ProfileState());

  void seed(UserModel user) {
    if (state.user == null) state = state.copyWith(user: user);
  }

  /// Load Profile
  Future<void> loadProfile() async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      fieldErrors: const {},
    );

    try {
      final user = await repository.getProfile();
      state = state.copyWith(user: user, clearError: true);
    } catch (e) {
      state = state.copyWith(error: _handleError(e));
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Update Profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      fieldErrors: const {},
    );

    try {
      final updatedUser = await repository.updateProfile(data);
      state = state.copyWith(
        user: updatedUser,
        clearError: true,
        fieldErrors: const {},
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: _handleError(e),
        fieldErrors: e is ProfileApiException ? e.fieldErrors : const {},
      );
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void clearFieldError(String field) {
    if (!state.fieldErrors.containsKey(field)) return;
    final next = Map<String, String>.from(state.fieldErrors)..remove(field);
    state = state.copyWith(fieldErrors: next);
  }

  /// Upload Profile Image
  Future<bool> uploadProfileImage(String filePath) async {
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      fieldErrors: const {},
    );

    try {
      final updatedUser = await repository.uploadProfileImage(filePath);
      state = state.copyWith(user: updatedUser, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: _handleError(e));
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
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
    if (error is ProfileApiException) return error.message;
    if (error is DioException) {
      return error.response?.data['message'] ?? "Network error occurred";
    }
    return "Something went wrong";
  }
}
