import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';
import '../state/auth_state.dart';

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  () => AuthViewModel(),
);

class AuthViewModel extends Notifier<AuthState> {
  late AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    return AuthState();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final user = await _repository.login(email, password);

      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: "Login failed",
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final success = await _repository.signup(name, email, password);

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
        errorMessage: e.toString(),
      );
    }
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
      // TODO: Implement Google Sign In in Repository
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> getProfile() async {
    try {
      final user = await _repository.getProfile();
      if (user != null) {
        state = state.copyWith(user: user);
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
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
        state = state.copyWith(
          status: AuthStatus.success, // or otpSent if you have it
        );
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
