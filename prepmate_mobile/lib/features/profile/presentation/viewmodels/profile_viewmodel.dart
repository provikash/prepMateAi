class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository repository;

  AuthViewModel(this.repository) : super(AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await repository.login(email, password);

      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> loadProfile() async {
    try {
      final user = await repository.getProfile();
      state = state.copyWith(user: user);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> logout() async {
    await repository.logout();
    state = AuthState(); // reset
  }
}