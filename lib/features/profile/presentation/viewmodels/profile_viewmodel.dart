import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'profile_state.dart';
import 'package:prepmate_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:prepmate_mobile/features/auth/data/models/user_model.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../domain/entities/profile_lifecycle_models.dart';

class ProfileViewModel extends StateNotifier<ProfileState> {
  final ProfileRepository repository;
  StreamSubscription? _profileSubscription;

  ProfileViewModel(this.repository) : super(ProfileState());

  void seed(UserModel user) {
    if (state.user == null) state = state.copyWith(user: user);
  }

  /// Load Profile
  Future<void> loadProfile() async {
    if (_profileSubscription != null) {
      await refresh();
      return;
    }
    state = state.copyWith(
      isLoading: state.user == null,
      clearError: true,
      fieldErrors: const {},
    );
    _profileSubscription = repository.watchProfile().listen(
      (cached) {
        state = state.copyWith(
          user: cached.value,
          isLoading: false,
          clearError: true,
          isOffline: cached.isOffline,
          isStale: cached.isStale,
          updatedAt: cached.updatedAt,
        );
      },
      onError: (Object error) {
        state = state.copyWith(isLoading: false, error: _handleError(error));
      },
    );
  }

  /// Load Profile Metadata (countries, industries, time zones)
  Future<void> loadMetadata() async {
    try {
      final metadata = await repository.getMetadata();
      state = state.copyWith(profileMetadata: metadata);
    } catch (_) {}
  }

  void setSaveStatus(ProfileSaveStatus status) {
    state = state.copyWith(saveStatus: status);
  }

  /// Update Profile with Autosave and Optimistic-Locking Conflict Detection
  Future<bool> updateProfile(
    Map<String, dynamic> data, {
    bool isAutosave = false,
    int? expectedVersion,
  }) async {
    if (state.isLoading && !isAutosave) return false;

    final versionToPass = expectedVersion ?? state.user?.version;
    final payload = <String, dynamic>{
      ...data,
      if (versionToPass != null) 'expected_version': versionToPass,
    };

    state = state.copyWith(
      isLoading: !isAutosave,
      saveStatus: ProfileSaveStatus.saving,
      clearError: true,
      fieldErrors: const {},
    );

    try {
      final updatedUser = await repository.updateProfile(payload);
      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
        saveStatus: ProfileSaveStatus.saved,
        lastSavedAt: DateTime.now(),
        clearError: true,
        clearConflict: true,
        fieldErrors: const {},
        isOffline: false,
      );
      return true;
    } on ProfileConflictException catch (e) {
      state = state.copyWith(
        isLoading: false,
        saveStatus: ProfileSaveStatus.saveFailed,
        isConflict: true,
        conflictServerData: e.serverData,
        serverVersion: e.serverVersion,
        error: e.message,
      );
      return false;
    } catch (e) {
      final isNetwork = e is DioException &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout);

      if (isNetwork) {
        // Stage to offline queue
        final queued = List<OfflineDraftItem>.from(state.offlineDraftQueue);
        for (final entry in data.entries) {
          if (entry.key != 'expected_version') {
            queued.add(OfflineDraftItem(
              field: entry.key,
              label: _fieldLabel(entry.key),
              displayValue: entry.value?.toString() ?? '',
              timestamp: DateTime.now(),
            ));
          }
        }
        state = state.copyWith(
          isLoading: false,
          saveStatus: ProfileSaveStatus.offlinePending,
          isOffline: true,
          offlineDraftQueue: queued,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          saveStatus: ProfileSaveStatus.saveFailed,
          error: _handleError(e),
          fieldErrors: e is ProfileApiException ? e.fieldErrors : const {},
        );
      }
      return false;
    }
  }

  static String _fieldLabel(String key) {
    switch (key) {
      case 'full_name':
        return 'Full Name';
      case 'preferred_name':
        return 'Preferred Name';
      case 'job_title':
        return 'Professional Title';
      case 'city':
        return 'City';
      case 'state_region':
        return 'State / Region';
      case 'country':
        return 'Country';
      case 'industry':
        return 'Industry';
      case 'linkedin':
      case 'linkedin_url':
        return 'LinkedIn Profile';
      case 'github':
      case 'github_url':
        return 'GitHub Portfolio';
      case 'portfolio_url':
        return 'Personal Website';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Resolve Conflict by picking field-by-field or batch winner
  Future<bool> resolveConflict({
    required Map<String, dynamic> resolvedFields,
    required int serverVersion,
  }) async {
    final payload = <String, dynamic>{
      ...resolvedFields,
      'expected_version': serverVersion,
    };
    final success = await updateProfile(payload, expectedVersion: serverVersion);
    if (success) {
      state = state.copyWith(clearConflict: true);
    }
    return success;
  }

  void clearConflict() {
    state = state.copyWith(clearConflict: true);
  }

  /// Save Offline Draft explicitly
  void saveOfflineDraft(Map<String, dynamic> fields) {
    final queued = <OfflineDraftItem>[];
    for (final entry in fields.entries) {
      queued.add(OfflineDraftItem(
        field: entry.key,
        label: _fieldLabel(entry.key),
        displayValue: entry.value?.toString() ?? '',
        timestamp: DateTime.now(),
      ));
    }
    state = state.copyWith(
      offlineDraftQueue: queued,
      isOffline: true,
      saveStatus: ProfileSaveStatus.offlinePending,
    );
  }

  /// Sync Offline Draft when reconnected
  Future<bool> syncOfflineDraft() async {
    if (state.offlineDraftQueue.isEmpty) return true;
    final payload = <String, dynamic>{};
    for (final item in state.offlineDraftQueue) {
      payload[item.field] = item.displayValue;
    }
    final success = await updateProfile(payload);
    if (success) {
      state = state.copyWith(
        offlineDraftQueue: const [],
        isOffline: false,
        saveStatus: ProfileSaveStatus.saved,
      );
    }
    return success;
  }

  void clearOfflineDraft() {
    state = state.copyWith(
      offlineDraftQueue: const [],
      saveStatus: ProfileSaveStatus.saved,
    );
  }

  /// Complete Onboarding
  Future<bool> completeOnboarding() async {
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      fieldErrors: const {},
    );

    try {
      final updatedUser = await repository.completeOnboarding();
      state = state.copyWith(
        user: updatedUser,
        clearError: true,
        fieldErrors: const {},
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: _handleError(e),
        fieldErrors: e is ProfileApiException ? e.fieldErrors : const {},
      );
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void clearFieldError(String field) {
    if (!state.fieldErrors.containsKey(field)) return;
    final next = Map<String, String>.from(state.fieldErrors)..remove(field);
    state = state.copyWith(fieldErrors: next);
  }

  /// Upload Profile Image
  Future<bool> uploadProfileImage(String filePath) async {
    state = state.copyWith(
      isAvatarUploading: true,
      clearAvatarError: true,
    );

    try {
      final updatedUser = await repository.uploadProfileImage(filePath);
      state = state.copyWith(
        user: updatedUser,
        isAvatarUploading: false,
        clearAvatarError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isAvatarUploading: false,
        avatarError: _handleError(e),
      );
      return false;
    }
  }

  /// Delete Profile Image
  Future<bool> deleteProfileImage() async {
    state = state.copyWith(
      isAvatarUploading: true,
      clearAvatarError: true,
    );

    try {
      final updatedUser = await repository.deleteProfileImage();
      state = state.copyWith(
        user: updatedUser,
        isAvatarUploading: false,
        clearAvatarError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isAvatarUploading: false,
        avatarError: _handleError(e),
      );
      return false;
    }
  }

  /// Cascade to Selected Resumes
  Future<CascadeResumesResult?> cascadeResumes(
    List<String> resumeIds, {
    List<String> fields = const ['job_title', 'location'],
  }) async {
    state = state.copyWith(isCascading: true);
    try {
      final result = await repository.cascadeResumes(resumeIds, fields: fields);
      state = state.copyWith(isCascading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isCascading: false);
      return null;
    }
  }

  /// Request phone number change challenge
  Future<bool> requestPhoneChange(String newPhoneNumber) async {
    state = state.copyWith(
      isPhoneChangeLoading: true,
      clearPhoneChangeError: true,
    );
    try {
      final res = await repository.requestPhoneChange(newPhoneNumber);
      final challengeId = res['challenge_id']?.toString() ??
          res['data']?['challenge_id']?.toString();
      state = state.copyWith(
        isPhoneChangeLoading: false,
        phoneChangeChallengeId: challengeId,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isPhoneChangeLoading: false,
        phoneChangeError: _handleError(e),
      );
      return false;
    }
  }

  /// Verify phone number change challenge
  Future<bool> verifyPhoneChange(String newPhoneNumber, String otp) async {
    final challengeId = state.phoneChangeChallengeId;
    if (challengeId == null) return false;
    state = state.copyWith(
      isPhoneChangeLoading: true,
      clearPhoneChangeError: true,
    );
    try {
      await repository.verifyPhoneChange(newPhoneNumber, challengeId, otp);
      state = state.copyWith(
        isPhoneChangeLoading: false,
        phoneChangeChallengeId: null,
      );
      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(
        isPhoneChangeLoading: false,
        phoneChangeError: _handleError(e),
      );
      return false;
    }
  }

  /// Refresh Profile
  Future<void> refresh() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: state.user == null, clearError: true);
    try {
      final fresh = await repository.refreshProfile();
      state = state.copyWith(
        user: fresh,
        isOffline: false,
        isStale: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isOffline: state.user != null,
        isStale: state.user != null,
        clearError: state.user != null,
        error: state.user == null ? _handleError(error) : null,
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Logout
  Future<void> logout() async {
    await _profileSubscription?.cancel();
    _profileSubscription = null;
    await repository.logout();
    state = ProfileState();
  }

  Future<void> loadPreferences() async {
    try {
      final prefs = await repository.getPreferences();
      state = state.copyWith(preferences: prefs);
    } catch (_) {}
  }

  Future<bool> updatePreferences(Map<String, dynamic> patch) async {
    try {
      final updated = await repository.updatePreferences(patch);
      state = state.copyWith(preferences: updated);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadExportStatus() async {
    try {
      final status = await repository.getDataExportStatus();
      state = state.copyWith(exportStatus: status);
    } catch (_) {}
  }

  Future<bool> requestExport() async {
    state = state.copyWith(isExportLoading: true);
    try {
      final status = await repository.requestDataExport();
      state = state.copyWith(exportStatus: status, isExportLoading: false);
      return true;
    } catch (_) {
      state = state.copyWith(isExportLoading: false);
      return false;
    }
  }

  Future<void> loadDeletionStatus() async {
    try {
      final status = await repository.getDeletionStatus();
      state = state.copyWith(deletionStatus: status);
    } catch (_) {}
  }

  Future<bool> scheduleDeletion({String? reason}) async {
    state = state.copyWith(isDeletionLoading: true);
    try {
      final status = await repository.scheduleDeletion(reason: reason);
      state = state.copyWith(deletionStatus: status, isDeletionLoading: false);
      return true;
    } catch (_) {
      state = state.copyWith(isDeletionLoading: false);
      return false;
    }
  }

  Future<bool> cancelDeletion() async {
    state = state.copyWith(isDeletionLoading: true);
    try {
      final status = await repository.cancelDeletion();
      state = state.copyWith(deletionStatus: status, isDeletionLoading: false);
      return true;
    } catch (_) {
      state = state.copyWith(isDeletionLoading: false);
      return false;
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }

  /// Centralized Error Handler
  String _handleError(dynamic error) {
    if (error is ProfileConflictException) return error.message;
    if (error is ProfileApiException) return error.message;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        if (data['detail'] != null) return data['detail'].toString();
        if (data['message'] != null) return data['message'].toString();
        if (data['error'] != null) return data['error'].toString();
      }
      return "Network error occurred. Please check connection.";
    }
    return "Something went wrong";
  }
}
