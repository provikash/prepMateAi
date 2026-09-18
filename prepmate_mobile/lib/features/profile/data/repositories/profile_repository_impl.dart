import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../../core/cache/cache_store.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remote;
  final AuthRemoteDataSource authRemote;
  final CacheCoordinator cache;
  final String? Function() userId;

  ProfileRepositoryImpl({
    required this.remote,
    required this.authRemote,
    required this.cache,
    required this.userId,
  });

  @override
  Future<UserModel> getProfile() {
    final id = userId();
    if (id == null || id.isEmpty) return remote.getProfile();
    return cache.get(
      key: CacheKeyFactory.user(id, 'profile'),
      userId: id,
      policy: CachePolicy.profile,
      decode: (value) =>
          UserModel.fromJson(Map<String, dynamic>.from(value! as Map)),
      encode: (value) => value.toJson(),
      remote: remote.getProfile,
    );
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final value = await remote.updateProfile(data);
    await _cacheProfile(value);
    return value;
  }

  @override
  Future<UserModel> uploadProfileImage(String filePath) async {
    final value = await remote.uploadProfileImage(filePath);
    await _cacheProfile(value);
    return value;
  }

  Future<void> _cacheProfile(UserModel value) async {
    final id = userId() ?? value.id;
    await cache.put(
      key: CacheKeyFactory.user(id, 'profile'),
      userId: id,
      policy: CachePolicy.profile,
      value: value,
      encode: (item) => item.toJson(),
    );
  }

  @override
  Future<void> logout() => authRemote.logout();
}
