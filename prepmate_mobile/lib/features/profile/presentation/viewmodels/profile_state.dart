import '../../../auth/data/models/user_model.dart';

class ProfileState {
  final bool isLoading;
  final String? error;
  final UserModel? user;

  ProfileState({this.isLoading = false, this.error, this.user});

  ProfileState copyWith({bool? isLoading, String? error, UserModel? user}) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}
