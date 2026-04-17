import '../entities/user.dart';

abstract class AuthRepository {
  Future<User?> login(String email, String password);

  Future<bool> signup(String name, String email, String password);

  Future<bool> verifyOtp(String email, String otp, String flow);

  Future<void> logout();

  Future<bool> forgotPassword(String email);

  Future<User?> getProfile();

  Future<User?> updateProfile(User user);
}
