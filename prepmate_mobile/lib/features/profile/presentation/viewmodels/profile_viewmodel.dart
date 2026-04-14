// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// // ✅ FIXED paths
// import 'package:prepmate_mobile/features/auth/domain/repositories/auth_repository.dart';
// import 'package:prepmate_mobile/features/auth/presentation/state/auth_state.dart';
//
// class ProfileViewModel extends StateNotifier<AuthState> {
//   final AuthRepository repository;
//
//   ProfileViewModel(this.repository) : super(AuthState());
//
//   /// Load user profile
//   Future<void> loadProfile() async {
//     state = state.copyWith(isLoading: true, error: null);
//
//     try {
//       final user = await repository.getProfile();
//
//       state = state.copyWith(
//         user: user,
//         isLoading: false,
//       );
//     } catch (e) {
//       state = state.copyWith(
//         error: e.toString(),
//         isLoading: false,
//       );
//     }
//   }
//
//   /// Logout user
//   Future<void> logout() async {
//     state = state.copyWith(isLoading: true);
//
//     try {
//       await repository.logout();
//
//       state = AuthState(); // reset بالكامل
//     } catch (e) {
//       state = state.copyWith(
//         error: e.toString(),
//         isLoading: false,
//       );
//     }
//   }
// }