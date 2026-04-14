import '../../domain/entities/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? error;
  final User? user;

  AuthState({this.status = AuthStatus.initial, this.error, this.user});

  AuthState copyWith({AuthStatus? status, String? error, User? user}) {
    return AuthState(
      status: status ?? this.status,
      error: error,
      user: user ?? this.user,
    );
  }
}
