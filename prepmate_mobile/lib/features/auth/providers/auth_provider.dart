import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:prepmate_mobile/core/services/storage.dart';
import '../../../../config/dio_client.dart';



import 'package:google_sign_in/google_sign_in.dart';

// Storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

// Auth state
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  success,
  otpSent,
}

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

  final tokenService = TokenService();
  AuthState build() => AuthState();


  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await ref
          .read(dioProvider)
          .post('auth/login/', data: {'email': email, 'password': password});
      if (response.statusCode == 200) {
        final access_token = response.data["tokens"]?["access"];

        await TokenService.saveToken(access_token);

        state = state.copyWith(status: AuthStatus.authenticated);
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

  Future<bool> verifyOtp(String otp, String email, String flow) async {
    try {
      final endpoint = flow == 'login'
          ? 'auth/verify-login-otp/'
          : flow == 'register'
          ? 'users/verify-otp/'
          : 'users/reset-password/';

      final data = flow == 'reset'
          ? {
              "email": email,
              "otp": otp,
              "new_password": "...", // send from reset screen
            }
          : {"email": email, "otp": otp};

      final response = await ref.read(dioProvider).post(endpoint, data: data);

      print("OTP RESPONSE STATUS: ${response.statusCode}");
      print("OTP RESPONSE DATA: ${response.data}");

      if (response.statusCode == 200) {
        // login flow → token returned
        if (flow == "login") {
          final token = response.data["tokens"]["access"];  // 🔥 FIX

          if (token != null) {
            await TokenService.saveToken('access_token'); // 🔥 USE SAME SERVICE

            print(await TokenService.getToken());
            state = state.copyWith(status: AuthStatus.authenticated);
          }
        }

        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: "Invalid OTP or network error",
      );
      return false;
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      final response = await ref
          .read(dioProvider)
          .post(
            'auth/register/', // your endpoint
            data: {
              'full_name':
                  name, // adjust key if your backend uses different name
              'email': email,
              'password': password,
              // 'confirm_password': password,  // if backend requires it
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(
          status: AuthStatus.success, // wait for OTP
          email: email,
        );
        // UI will navigate to OTP
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: response.data['message'] ?? 'Signup failed',
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
      final response = await ref
          .read(dioProvider)
          .post('auth/forgot-password/', data: {'email': email});

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
      final response = await ref
          .read(dioProvider)
          .post(
            'auth/reset-password/',
            data: {'email': email, 'otp': otp, 'new_password': newPassword},
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

  // Google Login FUnction
  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate();

      final GoogleSignInAuthentication auth = account.authentication;

      final idToken = auth.idToken;

      final response = await ref
          .read(dioProvider)
          .post('auth/google/', data: {"id_token": idToken});

      final token = response.data["tokens"]?["access"];


      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: "Google login failed",
      );
    }
  }
}
