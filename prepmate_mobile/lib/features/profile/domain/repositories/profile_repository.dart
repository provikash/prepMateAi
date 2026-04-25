import '../../../auth/data/models/user_model.dart';

abstract class ProfileRepository {
  /// Get logged-in user profile
  Future<UserModel> getProfile();

  /// Update profile (text fields)
  Future<UserModel> updateProfile(Map<String, dynamic> data);

  /// Upload profile image
  Future<UserModel> uploadProfileImage(String filePath);

  /// Logout user (optional here or move to AuthRepository)
  Future<void> logout();
}
