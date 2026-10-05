import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;

  AuthRepositoryImpl(this.remote);

  @override
  Future<OtpChallengeData> requestOtp(String phoneNumber) =>
      remote.requestOtp(phoneNumber);

  @override
  Future<OtpChallengeData> resendOtp(String phoneNumber, String challengeId) =>
      remote.resendOtp(phoneNumber, challengeId);

  @override
  Future<User> verifyOtp(String phoneNumber, String challengeId, String otp) =>
      remote.verifyOtp(phoneNumber, challengeId, otp);

  @override
  Future<void> logout() {
    return remote.logout();
  }

  @override
  Future<User?> getProfile() {
    return remote.getProfile();
  }

  @override
  Future<User?> updateProfile(User user) {
    return remote.updateProfile(user);
  }

  @override
  Future<User?> uploadProfileImage(String filePath) {
    return remote.uploadProfileImage(filePath);
  }
}
