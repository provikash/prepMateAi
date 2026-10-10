import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../../core/cache/cache_store.dart';
import '../../domain/entities/profile_lifecycle_models.dart';

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
  Stream<CachedValue<UserModel>> watchProfile() async* {
    final id = userId();
    if (id != null && id.isNotEmpty) {
      final key = CacheKeyFactory.user(id, 'profile');
      final entry = await cache.store.read(key);
      if (entry != null && entry.value != null) {
        try {
          final cachedUser = UserModel.fromJson(
            Map<String, dynamic>.from(entry.value! as Map),
          );
          yield CachedValue(
            value: cachedUser,
            updatedAt: entry.createdAt,
            isStale: !entry.isFresh(DateTime.now()),
          );
        } catch (_) {}
      }
    }
    try {
      final fresh = await remote.getProfile();
      await _cacheProfile(fresh);
      yield CachedValue(
        value: fresh,
        updatedAt: DateTime.now(),
        isStale: false,
      );
    } catch (_) {
      if (id == null || id.isEmpty) rethrow;
    }
  }

  @override
  Future<UserModel> refreshProfile() async {
    final fresh = await remote.getProfile();
    await _cacheProfile(fresh);
    return fresh;
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final value = await remote.updateProfile(data);
    await _cacheProfile(value);
    return value;
  }

  @override
  Future<UserModel> completeOnboarding() async {
    final value = await remote.completeOnboarding();
    await _cacheProfile(value);
    return value;
  }

  @override
  Future<UserModel> uploadProfileImage(String filePath) async {
    final value = await remote.uploadProfileImage(filePath);
    await _cacheProfile(value);
    return value;
  }

  @override
  Future<UserModel> deleteProfileImage() async {
    final value = await remote.deleteProfileImage();
    await _cacheProfile(value);
    return value;
  }

  @override
  Future<ProfileMetadata> getMetadata() => remote.getProfileMetadata();

  @override
  Future<CascadeResumesResult> cascadeResumes(List<String> resumeIds, {List<String> fields = const ['job_title', 'location']}) =>
      remote.cascadeResumes(resumeIds: resumeIds, fields: fields);

  @override
  Future<Map<String, dynamic>> requestPhoneChange(String newPhoneNumber) =>
      remote.requestPhoneChange(newPhoneNumber);

  @override
  Future<Map<String, dynamic>> verifyPhoneChange(String newPhoneNumber, String challengeId, String otp) =>
      remote.verifyPhoneChange(newPhoneNumber: newPhoneNumber, challengeId: challengeId, otp: otp);

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

  @override
  Future<UserPreferences> getPreferences() async {
    final data = await remote.getPreferences();
    return UserPreferences.fromJson(data);
  }

  @override
  Future<UserPreferences> updatePreferences(Map<String, dynamic> data) async {
    final res = await remote.updatePreferences(data);
    return UserPreferences.fromJson(res);
  }

  @override
  Future<DataExportStatus> getDataExportStatus() async {
    final data = await remote.getDataExportStatus();
    return DataExportStatus.fromJson(data);
  }

  @override
  Future<DataExportStatus> requestDataExport() async {
    final data = await remote.requestDataExport();
    return DataExportStatus.fromJson(data);
  }

  @override
  Future<AccountDeletionStatus> getDeletionStatus() async {
    final data = await remote.getDeletionStatus();
    return AccountDeletionStatus.fromJson(data);
  }

  @override
  Future<AccountDeletionStatus> scheduleDeletion({String? reason}) async {
    final data = await remote.scheduleDeletion(reason: reason);
    return AccountDeletionStatus.fromJson(data);
  }

  @override
  Future<AccountDeletionStatus> cancelDeletion() async {
    final data = await remote.cancelDeletion();
    return AccountDeletionStatus.fromJson(data);
  }
}

