// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../domain/repositories/auth_repository.dart';
// import '../state/auth_state.dart';
//
// final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
//   () => AuthViewModel(),
// );
//
// class AuthViewModel extends Notifier<AuthState> {
//   late AuthRepository _repository;
//
//   @override
//   AuthState build() {
//     _repository = ref.read(authRepositoryProvider);
//     return AuthState();
//   }
//
//   Future<void> login(String email, String password) async {
//     state = state.copyWith(status: AuthStatus.loading);
//
//     try {
//       final user = await _repository.login(email, password);
//
//       if (user != null) {
//         state = state.copyWith(status: AuthStatus.authenticated, user: user);
//       } else {
//         state = state.copyWith(status: AuthStatus.error, error: "Login failed");
//       }
//     } catch (e) {
//       state = state.copyWith(status: AuthStatus.error, error: e.toString());
//     }
//   }
//
//   Future<void> signup(String name, String email, String password) async {
//     state = state.copyWith(status: AuthStatus.loading);
//
//     try {
//       final success = await _repository.signup(name, email, password);
//
//       state = state.copyWith(
//         status: success ? AuthStatus.unauthenticated : AuthStatus.error,
//       );
//     } catch (e) {
//       state = state.copyWith(status: AuthStatus.error, error: e.toString());
//     }
//   }
//
//   Future<void> logout() async {
//     await _repository.logout();
//     state = AuthState(status: AuthStatus.unauthenticated);
//   }
// }
