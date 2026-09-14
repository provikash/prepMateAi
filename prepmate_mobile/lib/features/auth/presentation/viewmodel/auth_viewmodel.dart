import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';
import '../state/auth_state.dart';

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  () => AuthViewModel(),
);

final authProvider = authViewModelProvider;

class AuthViewModel extends Notifier<AuthState> {
  late AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    return AuthState();
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearInfo: true);
  }

  Future<void> bootstrapSession() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    final accessToken = await TokenService.getAccessToken();
    final refreshToken = await TokenService.getRefreshToken();
    if ((accessToken == null || accessToken.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        hasCheckedSession: true,
        clearError: true,
      );
      return;
    }

    final isValid = await getProfile(markSessionChecked: true);
    if (!isValid && state.status == AuthStatus.unauthenticated) {
      await TokenService.deleteToken();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        hasCheckedSession: true,
        infoMessage: 'Session expired, please login again',
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final user = await _repository.login(email, password);

      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          infoMessage: 'Login successful',
          hasCheckedSession: true,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: "Login failed",
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _normalizeAuthError(e),
      );
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final success = await _repository.signup(
        name,
        email,
        password,
        passwordConfirm,
      );

      if (success) {
        state = state.copyWith(status: AuthStatus.success, email: email);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: "Signup failed",
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _normalizeAuthError(e),
      );
    }
  }

  String _normalizeAuthError(Object error) {
    dynamic payload = error;
    if (error is DioException) payload = error.response?.data ?? error.message;
    final messages = <String>[];
    void collect(dynamic value) {
      if (value == null) return;
      if (value is Map) {
        final preferred = value['detail'] ?? value['message'];
        if (preferred != null && preferred.toString() != 'Request failed.') {
          collect(preferred);
        } else {
          value.forEach((key, nested) {
            if (!{'success', 'message'}.contains(key)) collect(nested);
          });
        }
      } else if (value is Iterable) {
        for (final nested in value) {
          collect(nested);
        }
      } else {
        final text = value.toString().replaceFirst('Exception: ', '').trim();
        if (text.isNotEmpty && !messages.contains(text)) messages.add(text);
      }
    }

    collect(payload);
    return messages.isEmpty
        ? 'Unable to complete the request. Please try again.'
        : messages.join(' ');
  }

  Future<void> verifyOtp(String email, String otp, String flow) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final success = await _repository.verifyOtp(email, otp, flow);
      if (success) {
        state = state.copyWith(
          status: AuthStatus.success,
          infoMessage: 'Email verified. Please sign in.',
          hasCheckedSession: true,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: "Verification failed",
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.signInWithGoogle();
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          infoMessage: 'Google login successful',
          hasCheckedSession: true,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Google login failed',
          hasCheckedSession: true,
        );
      }
    } catch (e) {
      final errorMsg = e.toString();

      // Handle Google Sign-In cancellation gracefully
      if (errorMsg.contains('cancelled') || errorMsg.contains('dismiss')) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          hasCheckedSession: true,
          clearError: true,
        );
        return;
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: errorMsg,
        hasCheckedSession: true,
      );
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (error) {
      await TokenService.deleteToken();
      debugPrint(
        'Backend logout failed; local credentials were cleared: $error',
      );
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

  /// Fetches profile and validates token.
  /// Returns true if token is valid and profile is fetched.
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
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        hasCheckedSession: markSessionChecked ? true : state.hasCheckedSession,
      );
      return false;
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      final unauthorized = e is DioException && e.response?.statusCode == 401;
      state = state.copyWith(
        status: unauthorized ? AuthStatus.unauthenticated : AuthStatus.error,
        hasCheckedSession: markSessionChecked ? true : state.hasCheckedSession,
        errorMessage: unauthorized
            ? null
            : 'Unable to verify your session. Check your connection and try again.',
        clearError: unauthorized,
      );
      return false;
    }
  }

  Future<void> updateProfile(User user) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final updatedUser = await _repository.updateProfile(user);
      if (updatedUser != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: updatedUser,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: "Failed to update profile",
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final success = await _repository.forgotPassword(email);

      if (success) {
        state = state.copyWith(status: AuthStatus.success);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: "Failed to send OTP",
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final success = await _repository.resetPassword(email, otp, newPassword);
      state = state.copyWith(
        status: success ? AuthStatus.success : AuthStatus.error,
        infoMessage: success ? 'Password changed. Please sign in.' : null,
        errorMessage: success ? null : 'Password reset failed.',
        hasCheckedSession: true,
      );
      return success;
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _normalizeAuthError(error),
      );
      return false;
    }
  }

  Future<bool> resendVerification(String email) async {
    try {
      return await _repository.resendVerification(email);
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _normalizeAuthError(error),
      );
      return false;
    }
  }
}
