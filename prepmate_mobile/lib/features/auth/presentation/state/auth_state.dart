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

  AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.email,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? email,
    User? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      email: email ?? this.email,
      user: user ?? this.user,
    );
  }
}
