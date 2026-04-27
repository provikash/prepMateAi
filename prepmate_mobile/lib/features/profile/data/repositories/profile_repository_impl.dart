import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remote;
  final AuthRemoteDataSource authRemote;

  ProfileRepositoryImpl({required this.remote, required this.authRemote});

  @override
  Future<UserModel> getProfile() => remote.getProfile();

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) =>
      remote.updateProfile(data);

  @override
  Future<UserModel> uploadProfileImage(String filePath) =>
      remote.uploadProfileImage(filePath);

  @override
  Future<void> logout() => authRemote.logout();
}
