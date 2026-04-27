import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import '../viewmodels/profile_state.dart';
import '../viewmodels/profile_viewmodel.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(ref.watch(dioProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    remote: ref.watch(profileRemoteDataSourceProvider),
    authRemote: ref.watch(authRemoteDataSourceProvider),
  );
});

final profileProvider = StateNotifierProvider<ProfileViewModel, ProfileState>((
  ref,
) {
  return ProfileViewModel(ref.watch(profileRepositoryProvider));
});

final isProfileIncompleteProvider = Provider<bool>((ref) {
  final user = ref.watch(profileProvider).user;
  if (user == null) {
    return false;
  }

  final missingName = (user.fullName ?? '').trim().isEmpty;
  final missingPhone = (user.phoneNumber ?? '').trim().isEmpty;
  return missingName || missingPhone;
});
