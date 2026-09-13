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
  final String? infoMessage;
  final String? email;
  final User? user;
  final bool isLoading;
  final bool hasCheckedSession;

  AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.infoMessage,
    this.email,
    this.user,
    this.isLoading = false,
    this.hasCheckedSession = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? infoMessage,
    String? email,
    User? user,
    bool? isLoading,
    bool? hasCheckedSession,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
      email: email ?? this.email,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      hasCheckedSession: hasCheckedSession ?? this.hasCheckedSession,
    );
  }
}
