import '../../domain/entities/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? error;
  final bool isLoading;
  final User? user;

  AuthState({this.status = AuthStatus.initial, this.error, this.user ,this.isLoading = false, });

  AuthState copyWith({AuthStatus? status, String? error, User? user ,bool ?isLoading}) {
    return AuthState(
      status: status ?? this.status,
      error: error,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
    );
  }
}
