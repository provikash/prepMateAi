import '../../../auth/data/models/user_model.dart';

class ProfileState {
  final bool isLoading;
  final String? error;
  final Map<String, String> fieldErrors;
  final UserModel? user;
  final bool isOffline;
  final bool isStale;
  final DateTime? updatedAt;

  ProfileState({
    this.isLoading = false,
    this.error,
    this.fieldErrors = const {},
    this.user,
    this.isOffline = false,
    this.isStale = false,
    this.updatedAt,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, String>? fieldErrors,
    UserModel? user,
    bool? isOffline,
    bool? isStale,
    DateTime? updatedAt,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      user: user ?? this.user,
      isOffline: isOffline ?? this.isOffline,
      isStale: isStale ?? this.isStale,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
