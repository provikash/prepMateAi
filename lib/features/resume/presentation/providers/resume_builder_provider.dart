import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/template_detail_model.dart';

/// UI-only builder state. The actual resume draft continues to live in
/// [resumeFormProvider], so AI actions and the create-resume API keep using
/// the same payload as before.
class ResumeBuilderState {
  final String? templateId;
  final String title;
  final List<FormSectionModel> steps;
  final int currentStep;
  final bool isSaving;
  final String? errorMessage;

  const ResumeBuilderState({
    this.templateId,
    this.title = 'Create Resume',
    this.steps = const [],
    this.currentStep = 0,
    this.isSaving = false,
    this.errorMessage,
  });

  int get totalSteps => steps.length;
  FormSectionModel? get currentSection =>
      steps.isEmpty ? null : steps[currentStep.clamp(0, steps.length - 1) as int];

  ResumeBuilderState copyWith({
    String? templateId,
    String? title,
    List<FormSectionModel>? steps,
    int? currentStep,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) => ResumeBuilderState(
    templateId: templateId ?? this.templateId,
    title: title ?? this.title,
    steps: steps ?? this.steps,
    currentStep: currentStep ?? this.currentStep,
    isSaving: isSaving ?? this.isSaving,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

class ResumeBuilderNotifier extends StateNotifier<ResumeBuilderState> {
  ResumeBuilderNotifier() : super(const ResumeBuilderState());

  void configure(TemplateDetailModel template) {
    // Keep the user's place if the same template rebuilds after an async
    // provider refresh; a different template starts a new flow.
    final keepStep = state.templateId == template.id;
    state = ResumeBuilderState(
      templateId: template.id,
      title: template.title,
      steps: template.sections,
      currentStep: keepStep && state.currentStep < template.sections.length
          ? state.currentStep
          : 0,
    );
  }

  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1, clearError: true);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1, clearError: true);
    }
  }

  void goToStep(int index) {
    if (index >= 0 && index < state.totalSteps) {
      state = state.copyWith(currentStep: index, clearError: true);
    }
  }

  void setSaving(bool value) => state = state.copyWith(isSaving: value);

  void setError(String? message) => state = state.copyWith(
    errorMessage: message,
    clearError: message == null,
  );
}

final resumeBuilderProvider =
    StateNotifierProvider<ResumeBuilderNotifier, ResumeBuilderState>((ref) {
      return ResumeBuilderNotifier();
    });
