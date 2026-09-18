import '../../../auth/data/models/user_model.dart';

class ProfileState {
  final bool isLoading;
  final String? error;
  final Map<String, String> fieldErrors;
  final UserModel? user;

  ProfileState({
    this.isLoading = false,
    this.error,
    this.fieldErrors = const {},
    this.user,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, String>? fieldErrors,
    UserModel? user,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      user: user ?? this.user,
    );
  }
}
