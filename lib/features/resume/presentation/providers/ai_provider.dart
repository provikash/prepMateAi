import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../config/dio_client.dart';
import '../../../../../core/providers/form_provider.dart';

enum AIStatus { initial, loading, success, error }

class AIState {
  final AIStatus status;
  final String? taskId;
  final String? action;
  final String? result;
  final String? userEditedResult;
  final String? appliedValue;
  final List<String> variations;
  final int selectedVariationIndex;
  final List<String> bullets;
  final Set<int> confirmedBullets;
  final List<String> skills;
  final Set<String> confirmedSkills;
  final String? targetResumeId;
  final String? targetResumeTitle;
  final int creditsUsed;
  final String? errorMessage;
  final Map<String, dynamic>? rawMap;

  AIState({
    this.status = AIStatus.initial,
    this.taskId,
    this.action,
    this.result,
    this.userEditedResult,
    this.appliedValue,
    this.variations = const [],
    this.selectedVariationIndex = 0,
    this.bullets = const [],
    this.confirmedBullets = const {},
    this.skills = const [],
    this.confirmedSkills = const {},
    this.targetResumeId,
    this.targetResumeTitle,
    this.creditsUsed = 1,
    this.errorMessage,
    this.rawMap,
  });

  String get activeResult {
    if (userEditedResult != null && userEditedResult!.isNotEmpty) {
      return userEditedResult!;
    }
    if (variations.isNotEmpty &&
        selectedVariationIndex >= 0 &&
        selectedVariationIndex < variations.length) {
      return variations[selectedVariationIndex];
    }
    return result ?? '';
  }

  AIState copyWith({
    AIStatus? status,
    String? taskId,
    String? action,
    String? result,
    String? userEditedResult,
    String? appliedValue,
    List<String>? variations,
    int? selectedVariationIndex,
    List<String>? bullets,
    Set<int>? confirmedBullets,
    List<String>? skills,
    Set<String>? confirmedSkills,
    String? targetResumeId,
    String? targetResumeTitle,
    int? creditsUsed,
    String? errorMessage,
    Map<String, dynamic>? rawMap,
  }) {
    return AIState(
      status: status ?? this.status,
      taskId: taskId ?? this.taskId,
      action: action ?? this.action,
      result: result ?? this.result,
      userEditedResult: userEditedResult ?? this.userEditedResult,
      appliedValue: appliedValue ?? this.appliedValue,
      variations: variations ?? this.variations,
      selectedVariationIndex:
          selectedVariationIndex ?? this.selectedVariationIndex,
      bullets: bullets ?? this.bullets,
      confirmedBullets: confirmedBullets ?? this.confirmedBullets,
      skills: skills ?? this.skills,
      confirmedSkills: confirmedSkills ?? this.confirmedSkills,
      targetResumeId: targetResumeId ?? this.targetResumeId,
      targetResumeTitle: targetResumeTitle ?? this.targetResumeTitle,
      creditsUsed: creditsUsed ?? this.creditsUsed,
      errorMessage: errorMessage ?? this.errorMessage,
      rawMap: rawMap ?? this.rawMap,
    );
  }
}

final aiProvider = StateNotifierProvider<AINotifier, AIState>((ref) {
  return AINotifier(ref, ref.read(dioProvider));
});

class AINotifier extends StateNotifier<AIState> {
  final Ref _ref;
  final Dio _dio;

  AINotifier(this._ref, this._dio) : super(AIState());

  void setResultForTesting({
    required String toolType,
    required String result,
    List<String> variants = const [],
  }) {
    state = state.copyWith(
      status: AIStatus.success,
      action: toolType,
      result: result,
      variations: variants,
      bullets: toolType == 'bullets' ? variants : const [],
      skills: toolType == 'skills' ? variants : const [],
    );
  }

  Future<void> submitAIAction(
    String action,
    Map<String, dynamic> data, {
    String? targetResumeId,
    String? targetResumeTitle,
    int creditCost = 1,
  }) async {
    state = state.copyWith(
      status: AIStatus.loading,
      action: action,
      errorMessage: null,
      result: null,
      userEditedResult: null,
      appliedValue: null,
      targetResumeId: targetResumeId,
      targetResumeTitle: targetResumeTitle ?? 'Software Engineer Resume',
      creditsUsed: creditCost,
      confirmedBullets: const {},
      confirmedSkills: const {},
    );

    try {
      final normalizedAction = action.replaceAll('_', '-');
      final response = await _dio.post('ai/$normalizedAction/', data: data);
      final dynamic raw = response.data;
      final rawMap = raw is Map ? Map<String, dynamic>.from(raw) : null;

      final displayResult = _extractDisplayString(action, raw);
      final variations = _extractVariations(action, raw, displayResult);
      final bullets = _extractBullets(action, raw);
      final skills = _extractSkills(action, raw);

      state = state.copyWith(
        status: AIStatus.success,
        result: displayResult,
        variations: variations,
        selectedVariationIndex: variations.length > 1
            ? 1
            : 0, // default Balanced
        bullets: bullets,
        skills: skills,
        rawMap: rawMap,
        taskId: null,
      );
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final detail = responseData is Map
          ? (responseData['message'] ??
                    responseData['detail'] ??
                    'AI service is unavailable. Please try again.')
                .toString()
          : (e.message ?? 'AI service is unavailable. Please try again.');
      state = state.copyWith(status: AIStatus.error, errorMessage: detail);
    } catch (e) {
      state = state.copyWith(
        status: AIStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void selectVariation(int index) {
    if (index >= 0 && index < state.variations.length) {
      state = state.copyWith(
        selectedVariationIndex: index,
        userEditedResult: null, // resets uncommitted edits on variant switch
      );
    }
  }

  void updateUserEdit(String editedText) {
    state = state.copyWith(userEditedResult: editedText);
  }

  void toggleBulletConfirmation(int index) {
    final updated = Set<int>.from(state.confirmedBullets);
    if (updated.contains(index)) {
      updated.remove(index);
    } else {
      updated.add(index);
    }
    state = state.copyWith(confirmedBullets: updated);
  }

  void toggleSkillConfirmation(String skill) {
    final updated = Set<String>.from(state.confirmedSkills);
    if (updated.contains(skill)) {
      updated.remove(skill);
    } else {
      updated.add(skill);
    }
    state = state.copyWith(confirmedSkills: updated);
  }

  void applyToResume({
    String mode = 'replace',
    int? experienceIndex,
    String? targetSection,
  }) {
    final form = _ref.read(resumeFormProvider.notifier);
    final textToApply = state.activeResult;

    if (state.action == 'generate_summary' ||
        state.action == 'improve_section') {
      if (textToApply.isNotEmpty) {
        form.updateSummary(textToApply);
        state = state.copyWith(appliedValue: textToApply);
      }
    } else if (state.action == 'generate_bullets') {
      final confirmed = state.confirmedBullets.isEmpty
          ? state.bullets
          : state.bullets
                .asMap()
                .entries
                .where((e) => state.confirmedBullets.contains(e.key))
                .map((e) => e.value)
                .toList();

      if (confirmed.isNotEmpty) {
        if (form.experienceItems.isEmpty) {
          form.addExperience();
        }
        final items = form.experienceItems;
        if (items.isNotEmpty) {
          final targetIdx = experienceIndex ?? 0;
          final first = Map<String, dynamic>.from(items[targetIdx]);
          final existing = List<String>.from(
            first['bullets'] as List? ?? const [],
          );
          if (mode == 'replace') {
            first['bullets'] = confirmed;
          } else {
            existing.addAll(confirmed);
            first['bullets'] = existing;
          }
          form.updateExperience(targetIdx, first);
          state = state.copyWith(appliedValue: confirmed.join('\n'));
        }
      }
    } else if (state.action == 'suggest_skills') {
      final skillsToApply = state.confirmedSkills.isEmpty
          ? state.skills
          : state.confirmedSkills.toList();
      for (final skill in skillsToApply) {
        form.addSkill(skill);
      }
      state = state.copyWith(appliedValue: skillsToApply.join(', '));
    }
  }

  void reset() {
    state = AIState();
  }

  String _extractDisplayString(String? action, dynamic result) {
    if (result == null) return '';
    if (result is String) return result;
    if (result is Map) {
      switch (action) {
        case 'generate_summary':
          return result['summary']?.toString() ?? result.toString();
        case 'improve_section':
          return result['improved_text']?.toString() ?? result.toString();
        case 'suggest_skills':
          final skills = result['skills'];
          if (skills is List) return skills.join(', ');
          return result.toString();
        case 'generate_bullets':
          final bullets = result['bullets'];
          if (bullets is List) {
            return bullets.map((b) => '• $b').join('\n');
          }
          return result.toString();
      }
    }
    return result.toString();
  }

  List<String> _extractVariations(
    String? action,
    dynamic result,
    String primaryResult,
  ) {
    if (action != 'generate_summary' && action != 'improve_section') {
      return [primaryResult];
    }
    if (primaryResult.isEmpty) return [];
    return [primaryResult];
  }

  List<String> _extractBullets(String? action, dynamic result) {
    if (action != 'generate_bullets') return [];
    if (result is Map && result['bullets'] is List) {
      return List<String>.from(
        (result['bullets'] as List).map((b) => b.toString()),
      );
    }
    return [];
  }

  List<String> _extractSkills(String? action, dynamic result) {
    if (action != 'suggest_skills') return [];
    if (result is Map && result['skills'] is List) {
      return List<String>.from(
        (result['skills'] as List).map((s) => s.toString()),
      );
    }
    return [];
  }
}
