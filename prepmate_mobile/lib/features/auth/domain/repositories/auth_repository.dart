import '../entities/user.dart';

abstract class AuthRepository {
  Future<User?> login(String email, String password);

  Future<User?> signInWithGoogle();

  Future<bool> signup(
    String name,
    String email,
    String password,
    String passwordConfirm,
  );

  Future<bool> verifyOtp(String email, String otp, String flow);

  Future<void> logout();

  Future<bool> forgotPassword(String email);

  Future<bool> resetPassword(String email, String otp, String newPassword);

  Future<bool> resendVerification(String email);

  Future<User?> getProfile();

  Future<User?> updateProfile(User user);
  Future<User?> uploadProfileImage(String filePath);
}
