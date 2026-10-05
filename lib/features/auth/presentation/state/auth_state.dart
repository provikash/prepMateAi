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
  final String? phoneNumber;
  final String? challengeId;
  final int resendAfterSeconds;
  final User? user;
  final bool isLoading;
  final bool hasCheckedSession;

  AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.infoMessage,
    this.phoneNumber,
    this.challengeId,
    this.resendAfterSeconds = 0,
    this.user,
    this.isLoading = false,
    this.hasCheckedSession = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? infoMessage,
    String? phoneNumber,
    String? challengeId,
    int? resendAfterSeconds,
    User? user,
    bool? isLoading,
    bool? hasCheckedSession,
    bool clearError = false,
    bool clearInfo = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
      phoneNumber: phoneNumber ?? this.phoneNumber,
      challengeId: challengeId ?? this.challengeId,
      resendAfterSeconds: resendAfterSeconds ?? this.resendAfterSeconds,
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      hasCheckedSession: hasCheckedSession ?? this.hasCheckedSession,
    );
  }
}
