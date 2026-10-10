import '../../../auth/data/models/user_model.dart';
import '../../domain/entities/profile_lifecycle_models.dart';

enum ProfileSaveStatus {
  saved,
  saving,
  unsaved,
  saveFailed,
  offlinePending,
}

class ProfileState {
  final bool isLoading;
  final String? error;
  final Map<String, String> fieldErrors;
  final UserModel? user;
  final bool isOffline;
  final bool isStale;
  final DateTime? updatedAt;
  final UserPreferences preferences;
  final DataExportStatus? exportStatus;
  final AccountDeletionStatus? deletionStatus;
  final bool isExportLoading;
  final bool isDeletionLoading;

  // Personal Information Batch 8 additions
  final ProfileSaveStatus saveStatus;
  final bool isConflict;
  final Map<String, dynamic>? conflictServerData;
  final int? serverVersion;
  final ProfileMetadata profileMetadata;
  final List<OfflineDraftItem> offlineDraftQueue;
  final bool isCascading;
  final DateTime? lastSavedAt;
  final bool isAvatarUploading;
  final String? avatarError;
  final String? phoneChangeChallengeId;
  final bool isPhoneChangeLoading;
  final String? phoneChangeError;

  ProfileState({
    this.isLoading = false,
    this.error,
    this.fieldErrors = const {},
    this.user,
    this.isOffline = false,
    this.isStale = false,
    this.updatedAt,
    this.preferences = const UserPreferences(),
    this.exportStatus,
    this.deletionStatus,
    this.isExportLoading = false,
    this.isDeletionLoading = false,
    this.saveStatus = ProfileSaveStatus.saved,
    this.isConflict = false,
    this.conflictServerData,
    this.serverVersion,
    this.profileMetadata = const ProfileMetadata(),
    this.offlineDraftQueue = const [],
    this.isCascading = false,
    this.lastSavedAt,
    this.isAvatarUploading = false,
    this.avatarError,
    this.phoneChangeChallengeId,
    this.isPhoneChangeLoading = false,
    this.phoneChangeError,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, String>? fieldErrors,
    UserModel? user,
    bool? isOffline,
    bool? isStale,
    DateTime? updatedAt,
    UserPreferences? preferences,
    DataExportStatus? exportStatus,
    AccountDeletionStatus? deletionStatus,
    bool? isExportLoading,
    bool? isDeletionLoading,
    ProfileSaveStatus? saveStatus,
    bool? isConflict,
    Map<String, dynamic>? conflictServerData,
    bool clearConflict = false,
    int? serverVersion,
    ProfileMetadata? profileMetadata,
    List<OfflineDraftItem>? offlineDraftQueue,
    bool? isCascading,
    DateTime? lastSavedAt,
    bool? isAvatarUploading,
    String? avatarError,
    bool clearAvatarError = false,
    String? phoneChangeChallengeId,
    bool? isPhoneChangeLoading,
    String? phoneChangeError,
    bool clearPhoneChangeError = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      user: user ?? this.user,
      isOffline: isOffline ?? this.isOffline,
      isStale: isStale ?? this.isStale,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      exportStatus: exportStatus ?? this.exportStatus,
      deletionStatus: deletionStatus ?? this.deletionStatus,
      isExportLoading: isExportLoading ?? this.isExportLoading,
      isDeletionLoading: isDeletionLoading ?? this.isDeletionLoading,
      saveStatus: saveStatus ?? this.saveStatus,
      isConflict: clearConflict ? false : (isConflict ?? this.isConflict),
      conflictServerData: clearConflict
          ? null
          : (conflictServerData ?? this.conflictServerData),
      serverVersion: clearConflict
          ? null
          : (serverVersion ?? this.serverVersion),
      profileMetadata: profileMetadata ?? this.profileMetadata,
      offlineDraftQueue: offlineDraftQueue ?? this.offlineDraftQueue,
      isCascading: isCascading ?? this.isCascading,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      isAvatarUploading: isAvatarUploading ?? this.isAvatarUploading,
      avatarError: clearAvatarError ? null : (avatarError ?? this.avatarError),
      phoneChangeChallengeId:
          phoneChangeChallengeId ?? this.phoneChangeChallengeId,
      isPhoneChangeLoading:
          isPhoneChangeLoading ?? this.isPhoneChangeLoading,
      phoneChangeError: clearPhoneChangeError
          ? null
          : (phoneChangeError ?? this.phoneChangeError),
    );
  }
}
