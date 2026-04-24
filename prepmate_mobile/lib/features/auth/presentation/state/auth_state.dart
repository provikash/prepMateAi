import '../../domain/entities/user.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  success,
}

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? email;
  final User? user;
  final bool isLoading;

  AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.email,
    this.user,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? email,
    User? user,
    bool? isLoading,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      email: email ?? this.email,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
