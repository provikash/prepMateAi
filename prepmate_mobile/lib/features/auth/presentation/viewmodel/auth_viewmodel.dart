import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../state/auth_state.dart';

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  () => AuthViewModel(),
);
final authProvider = authViewModelProvider;

class AuthViewModel extends Notifier<AuthState> {
  late AuthRepository _repository;
  bool _submitting = false;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    return AuthState();
  }

  void clearMessages() =>
      state = state.copyWith(clearError: true, clearInfo: true);

  Future<void> bootstrapSession() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    final access = await TokenService.getAccessToken();
    final refresh = await TokenService.getRefreshToken();
    if ((access == null || access.isEmpty) &&
        (refresh == null || refresh.isEmpty)) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        hasCheckedSession: true,
      );
      return;
    }
    final valid = await getProfile(markSessionChecked: true);
    if (!valid && state.status == AuthStatus.unauthenticated) {
      await TokenService.deleteToken();
    }
  }

  Future<bool> requestOtp(String phoneNumber) async {
    if (_submitting) return false;
    _submitting = true;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final challenge = await _repository.requestOtp(phoneNumber);
      state = state.copyWith(
        status: AuthStatus.success,
        phoneNumber: phoneNumber,
        challengeId: challenge.challengeId,
        resendAfterSeconds: challenge.resendAfterSeconds,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _authError(error),
      );
      return false;
    } finally {
      _submitting = false;
    }
  }

  Future<bool> resendOtp() async {
    if (_submitting || state.phoneNumber == null || state.challengeId == null) {
      return false;
    }
    _submitting = true;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final challenge = await _repository.resendOtp(
        state.phoneNumber!,
        state.challengeId!,
      );
      state = state.copyWith(
        status: AuthStatus.success,
        challengeId: challenge.challengeId,
        resendAfterSeconds: challenge.resendAfterSeconds,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _authError(error),
      );
      return false;
    } finally {
      _submitting = false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (_submitting || state.phoneNumber == null || state.challengeId == null) {
      return false;
    }
    _submitting = true;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _repository.verifyOtp(
        state.phoneNumber!,
        state.challengeId!,
        otp,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        hasCheckedSession: true,
        infoMessage: 'Signed in successfully',
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _authError(error),
      );
      return false;
    } finally {
      _submitting = false;
    }
  }

  String _authError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map &&
          data['message'] != null &&
          data['message'] != 'Request failed.') {
        return data['message'].toString();
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'You appear to be offline. Check your connection.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'The request timed out. Please try again.';
      }
    }
    return 'Unable to complete the request. Please try again.';
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (error) {
      await TokenService.deleteToken();
      debugPrint('Logout failed after local cleanup: $error');
    }
    state = AuthState(
      status: AuthStatus.unauthenticated,
      hasCheckedSession: true,
    );
  }

  Future<void> forceLogout({String? message}) async {
    await TokenService.deleteToken();
    state = AuthState(
      status: AuthStatus.unauthenticated,
      hasCheckedSession: true,
      infoMessage: message,
    );
  }

  Future<bool> getProfile({bool markSessionChecked = false}) async {
    try {
      final user = await _repository.getProfile();
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          hasCheckedSession: markSessionChecked
              ? true
              : state.hasCheckedSession,
          clearError: true,
        );
        return true;
      }
    } catch (error) {
      final unauthorized =
          error is DioException && error.response?.statusCode == 401;
      state = state.copyWith(
        status: unauthorized ? AuthStatus.unauthenticated : AuthStatus.error,
        hasCheckedSession: markSessionChecked ? true : state.hasCheckedSession,
        errorMessage: unauthorized ? null : 'Unable to restore your session.',
        clearError: unauthorized,
      );
      return false;
    }
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      hasCheckedSession: markSessionChecked ? true : state.hasCheckedSession,
    );
    return false;
  }

  Future<void> updateProfile(User user) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final updated = await _repository.updateProfile(user);
      state = state.copyWith(
        status: updated == null ? AuthStatus.error : AuthStatus.authenticated,
        user: updated,
        errorMessage: updated == null ? 'Failed to update profile.' : null,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _authError(error),
      );
    }
  }
}
