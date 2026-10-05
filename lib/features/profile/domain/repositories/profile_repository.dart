import '../../../auth/data/models/user_model.dart';
import '../../../../core/cache/cache_store.dart';

abstract class ProfileRepository {
  /// Get logged-in user profile
  Future<UserModel> getProfile();

  Stream<CachedValue<UserModel>> watchProfile();

  Future<UserModel> refreshProfile();

  /// Update profile (text fields)
  Future<UserModel> updateProfile(Map<String, dynamic> data);

  /// Upload profile image
  Future<UserModel> uploadProfileImage(String filePath);

  /// Mark onboarding complete
  Future<UserModel> completeOnboarding();

  /// Logout user (optional here or move to AuthRepository)
  Future<void> logout();
}
