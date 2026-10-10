import '../../../auth/data/models/user_model.dart';
import '../entities/profile_lifecycle_models.dart';

abstract class ProfileRepository {
  /// Get logged-in user profile
  Future<UserModel> getProfile();

  Stream<CachedValue<UserModel>> watchProfile();

  Future<UserModel> refreshProfile();

  /// Update profile (text fields)
  Future<UserModel> updateProfile(Map<String, dynamic> data);

  /// Upload profile image
  Future<UserModel> uploadProfileImage(String filePath);

  /// Delete profile image
  Future<UserModel> deleteProfileImage();

  /// Profile metadata (countries, industries, time zones)
  Future<ProfileMetadata> getMetadata();

  /// Cascade profile changes to selected resumes
  Future<CascadeResumesResult> cascadeResumes(List<String> resumeIds, {List<String> fields = const ['job_title', 'location']});

  /// Request phone number change challenge
  Future<Map<String, dynamic>> requestPhoneChange(String newPhoneNumber);

  /// Verify phone number change challenge
  Future<Map<String, dynamic>> verifyPhoneChange(String newPhoneNumber, String challengeId, String otp);

  /// Mark onboarding complete
  Future<UserModel> completeOnboarding();

  /// Logout user (optional here or move to AuthRepository)
  Future<void> logout();

  Future<UserPreferences> getPreferences();
  Future<UserPreferences> updatePreferences(Map<String, dynamic> data);
  Future<DataExportStatus> getDataExportStatus();
  Future<DataExportStatus> requestDataExport();
  Future<AccountDeletionStatus> getDeletionStatus();
  Future<AccountDeletionStatus> scheduleDeletion({String? reason});
  Future<AccountDeletionStatus> cancelDeletion();
}

