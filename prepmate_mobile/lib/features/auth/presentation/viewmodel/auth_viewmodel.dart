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
    final token = await TokenService.getToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        hasCheckedSession: true,
        clearError: true,
      );
      return;
    }

    final isValid = await getProfile(markSessionChecked: true);
    if (!isValid) {
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
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData != null) {
        if (responseData is Map<String, dynamic>) {
          return responseData.values
              .expand((value) => value is Iterable ? value : [value])
              .map((value) => value.toString())
              .join(' ');
        }
        return responseData.toString();
      }
    }
    return error.toString();
  }

  Future<void> verifyOtp(String email, String otp, String flow) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final success = await _repository.verifyOtp(email, otp, flow);
      if (success) {
        state = state.copyWith(status: AuthStatus.authenticated);
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
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        hasCheckedSession: true,
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState(
      status: AuthStatus.unauthenticated,
      hasCheckedSession: true,
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
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        hasCheckedSession: markSessionChecked ? true : state.hasCheckedSession,
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

  Future<void> forgotPassword(String email) async {
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
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
