import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../auth/presentation/viewmodel/auth_viewmodel.dart';

class OnboardingState {
  final int currentStep;
  final String? experienceLevel;
  final List<String> careerInterests;
  final List<String> careerGoals;
  final List<String> targetRoles;
  final String? fullName;
  final String? professionalTitle;
  final String? location;
  final String? email;
  final String? photoUrl;
  final bool isSaving;
  final String? errorMessage;

  const OnboardingState({
    this.currentStep = 0,
    this.experienceLevel,
    this.careerInterests = const [],
    this.careerGoals = const [],
    this.targetRoles = const [],
    this.fullName,
    this.professionalTitle,
    this.location,
    this.email,
    this.photoUrl,
    this.isSaving = false,
    this.errorMessage,
  });

  OnboardingState copyWith({
    int? currentStep,
    String? experienceLevel,
    List<String>? careerInterests,
    List<String>? careerGoals,
    List<String>? targetRoles,
    String? fullName,
    String? professionalTitle,
    String? location,
    String? email,
    String? photoUrl,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      careerInterests: careerInterests ?? this.careerInterests,
      careerGoals: careerGoals ?? this.careerGoals,
      targetRoles: targetRoles ?? this.targetRoles,
      fullName: fullName ?? this.fullName,
      professionalTitle: professionalTitle ?? this.professionalTitle,
      location: location ?? this.location,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(const OnboardingState()) {
    _initFromExistingUser();
  }

  void _initFromExistingUser() {
    final user = _ref.read(authViewModelProvider).user;
    if (user != null) {
      state = state.copyWith(
        currentStep: user.onboardingStep,
        experienceLevel: user.experienceLevel,
        careerInterests: user.careerInterests ?? const [],
        careerGoals: user.careerGoals ?? const [],
        targetRoles: user.targetRoles ?? const [],
        fullName: user.fullName,
        professionalTitle: user.professionalTitle,
        location: user.location,
        email: user.email,
        photoUrl: user.profilePictureUrl,
      );
    }
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step, clearError: true);
  }

  void setExperienceLevel(String level) {
    state = state.copyWith(experienceLevel: level, clearError: true);
  }

  void toggleInterest(String interest) {
    final list = List<String>.from(state.careerInterests);
    if (list.contains(interest)) {
      list.remove(interest);
    } else {
      list.add(interest);
    }
    state = state.copyWith(careerInterests: list, clearError: true);
  }

  void toggleGoal(String goal) {
    final list = List<String>.from(state.careerGoals);
    if (list.contains(goal)) {
      list.remove(goal);
    } else {
      list.add(goal);
    }
    state = state.copyWith(careerGoals: list, clearError: true);
  }

  void setBasicDetails({
    required String fullName,
    String? professionalTitle,
    String? location,
    String? email,
  }) {
    state = state.copyWith(
      fullName: fullName,
      professionalTitle: professionalTitle,
      location: location,
      email: email,
      clearError: true,
    );
  }

  Future<bool> saveProfileDetails({
    required String fullName,
    String? professionalTitle,
    String? location,
    String? email,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final repository = _ref.read(profileRepositoryProvider);
      final payload = <String, dynamic>{
        'full_name': fullName.trim(),
        'onboarding_step': 2,
      };
      if (professionalTitle != null && professionalTitle.trim().isNotEmpty) {
        payload['professional_title'] = professionalTitle.trim();
      }
      if (location != null && location.trim().isNotEmpty) {
        payload['location'] = location.trim();
      }
      if (email != null && email.trim().isNotEmpty) {
        payload['email'] = email.trim();
      }

      final updatedUser = await repository.updateProfile(payload);
      _ref.read(authViewModelProvider.notifier).syncUser(updatedUser);
      state = state.copyWith(
        fullName: updatedUser.fullName,
        professionalTitle: updatedUser.professionalTitle,
        location: updatedUser.location,
        email: updatedUser.email,
        currentStep: 2,
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: _formatError(e));
      return false;
    }
  }

  Future<bool> saveExperienceLevel(String level) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final repository = _ref.read(profileRepositoryProvider);
      final updatedUser = await repository.updateProfile({
        'experience_level': level,
        'onboarding_step': 3,
      });
      _ref.read(authViewModelProvider.notifier).syncUser(updatedUser);
      state = state.copyWith(
        experienceLevel: level,
        currentStep: 3,
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: _formatError(e));
      return false;
    }
  }

  Future<bool> savePreferencesAndGoals() async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final repository = _ref.read(profileRepositoryProvider);
      final updatedUser = await repository.updateProfile({
        'career_interests': state.careerInterests,
        'career_goals': state.careerGoals,
        'onboarding_step': 4,
      });
      _ref.read(authViewModelProvider.notifier).syncUser(updatedUser);
      state = state.copyWith(currentStep: 4, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: _formatError(e));
      return false;
    }
  }

  Future<bool> finalizeOnboarding() async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final repository = _ref.read(profileRepositoryProvider);
      final updatedUser = await repository.completeOnboarding();
      _ref.read(authViewModelProvider.notifier).syncUser(updatedUser);
      state = state.copyWith(currentStep: 5, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: _formatError(e));
      return false;
    }
  }

  String _formatError(dynamic error) {
    if (error is ProfileApiException) return error.message;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      return 'Network error occurred. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      return OnboardingNotifier(ref);
    });
