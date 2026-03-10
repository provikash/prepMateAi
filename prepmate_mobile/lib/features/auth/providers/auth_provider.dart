import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../config/dio_client.dart';

// Storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

// Auth state
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? email; // for OTP flow

  AuthState({this.status = AuthStatus.initial, this.errorMessage, this.email});

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? email,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      email: email ?? this.email,
    );
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState();

  // Login - Step 1: Send credentials → get OTP
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await ref
          .read(dioProvider)
          .post('auth/login/', data: {'email': email, 'password': password});
      if (response.statusCode == 200) {
        state = state.copyWith(
          status: AuthStatus.loading, // still loading for OTP
          email: email,
          errorMessage: null,
        );
        // Navigate to OTP screen from UI
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: response.data['detail'] ?? 'Login failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Network error: $e',
      );
    }
  }

  // Verify OTP (for login / signup / reset) - returns token on success
  Future<String?> verifyOtp(String otp, String email, String flow) async {
    // flow: 'login', 'register', 'reset'
    try {
      final endpoint = flow == 'login'
          ? 'auth/verify-login-otp/'
          : flow == 'register'
          ? 'auth/verify-otp/'
          : 'auth/reset-password/'; // adjust based on your backend

      final data = flow == 'reset'
          ? {
        'email': email,
        'otp': otp,
        'new_password': '...' /* from another screen */,
      }
          : {'email': email, 'otp': otp};

      final response = await ref.read(dioProvider).post(endpoint, data: data);

      if (response.statusCode == 200) {
        final token = response.data['token'] as String?;
        if (token != null) {
          await ref
              .read(secureStorageProvider)
              .write(key: 'auth_token', value: token);
          state = AuthState(status: AuthStatus.authenticated);
          return token;
        }
      }
      return null;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid OTP or error',
      );
      return null;
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await ref.read(dioProvider).post(
        'auth/register/', // your endpoint
        data: {
          'full_name': name, // adjust key if your backend uses different name
          'email': email,
          'password': password,
          // 'confirm_password': password,  // if backend requires it
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(
          status: AuthStatus.loading, // wait for OTP
          email: email,
          errorMessage: null,
        );
        // UI will navigate to OTP
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: response.data['detail'] ?? 'Signup failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Network error: $e',
      );
    }
  }


  // forget password Function

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await ref.read(dioProvider).post(
        'auth/forgot-password/',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          status: AuthStatus.loading, // waiting for OTP
          email: email,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: response.data['detail'] ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Network error: $e',
      );
    }
  }


  // reset Password

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final response = await ref.read(dioProvider).post(
        'auth/reset-password/',
        data: {
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: response.data['detail'] ?? 'Password reset failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Network error: $e',
      );
    }
  }

}

