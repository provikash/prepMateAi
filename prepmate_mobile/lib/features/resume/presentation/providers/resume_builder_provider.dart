import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/template_detail_model.dart';
import '../models/resume_journey.dart';

/// UI-only builder state. The actual resume draft continues to live in
/// [resumeFormProvider], so AI actions and the create-resume API keep using
/// the same payload as before.
class ResumeBuilderState {
  final String? templateId;
  final String title;
  final ResumeJourney journey;
  final int currentStep;
  final bool isSaving;
  final String? errorMessage;
  final String? savedResumeId;
  final String saveStatus;
  final Set<int> completedSteps;

  const ResumeBuilderState({
    this.templateId,
    this.title = 'Create Resume',
    this.journey = const ResumeJourney(steps: [], optionalSections: []),
    this.currentStep = 0,
    this.isSaving = false,
    this.errorMessage,
    this.savedResumeId,
    this.saveStatus = 'Not saved',
    this.completedSteps = const {},
  });

  List<ResumeJourneyStep> get steps => journey.steps;
  int get totalSteps => steps.length;
  ResumeJourneyStep? get currentStepData =>
      steps.isEmpty ? null : steps[currentStep.clamp(0, steps.length - 1)];

  ResumeBuilderState copyWith({
    String? templateId,
    String? title,
    ResumeJourney? journey,
    int? currentStep,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    String? savedResumeId,
    String? saveStatus,
    Set<int>? completedSteps,
  }) => ResumeBuilderState(
    templateId: templateId ?? this.templateId,
    title: title ?? this.title,
    journey: journey ?? this.journey,
    currentStep: currentStep ?? this.currentStep,
    isSaving: isSaving ?? this.isSaving,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    savedResumeId: savedResumeId ?? this.savedResumeId,
    saveStatus: saveStatus ?? this.saveStatus,
    completedSteps: completedSteps ?? this.completedSteps,
  );
}

class ResumeBuilderNotifier extends StateNotifier<ResumeBuilderState> {
  ResumeBuilderNotifier() : super(const ResumeBuilderState());

  void configure(TemplateDetailModel template) {
    // Keep the user's place if the same template rebuilds after an async
    // provider refresh; a different template starts a new flow.
    final keepStep = state.templateId == template.id;
    final journey = ResumeJourney.fromTemplate(template);
    state = ResumeBuilderState(
      templateId: template.id,
      title: template.title,
      journey: journey,
      currentStep: keepStep && state.currentStep < journey.steps.length
          ? state.currentStep
          : 0,
    );
  }

  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        clearError: true,
      );
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        clearError: true,
      );
    }
  }

  void goToStep(int index) {
    if (index >= 0 && index < state.totalSteps) {
      state = state.copyWith(currentStep: index, clearError: true);
    }
  }

  void setSaving(bool value) => state = state.copyWith(
    isSaving: value,
    saveStatus: value ? 'Saving…' : state.saveStatus,
  );

  void setSaved(String resumeId, {required bool draft}) =>
      state = state.copyWith(
        isSaving: false,
        savedResumeId: resumeId,
        saveStatus: draft ? 'Draft saved' : 'Saved',
        clearError: true,
      );

  void setError(String? message) => state = state.copyWith(
    isSaving: false,
    errorMessage: message,
    saveStatus: message == null ? state.saveStatus : 'Could not save',
    clearError: message == null,
  );

  void setSavedWithNewerChanges(String resumeId) => state = state.copyWith(
    isSaving: false,
    savedResumeId: resumeId,
    saveStatus: 'Saved; newer changes are not saved',
    clearError: true,
  );
}

final resumeBuilderProvider =
    StateNotifierProvider<ResumeBuilderNotifier, ResumeBuilderState>((ref) {
      return ResumeBuilderNotifier();
    });
