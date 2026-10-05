import '../entities/user.dart';

abstract class AuthRepository {
  Future<OtpChallengeData> requestOtp(String phoneNumber);
  Future<OtpChallengeData> resendOtp(String phoneNumber, String challengeId);
  Future<User> verifyOtp(String phoneNumber, String challengeId, String otp);

  Future<void> logout();

  Future<User?> getProfile();

  Future<User?> updateProfile(User user);
  Future<User?> uploadProfileImage(String filePath);
}

class OtpChallengeData {
  const OtpChallengeData({
    required this.challengeId,
    required this.resendAfterSeconds,
  });
  final String challengeId;
  final int resendAfterSeconds;
}
