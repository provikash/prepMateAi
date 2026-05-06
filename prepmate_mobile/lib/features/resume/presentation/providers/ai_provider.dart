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
  final String? errorMessage;

  AIState({
    this.status = AIStatus.initial,
    this.taskId,
    this.action,
    this.result,
    this.errorMessage,
  });

  AIState copyWith({
    AIStatus? status,
    String? taskId,
    String? action,
    String? result,
    String? errorMessage,
  }) {
    return AIState(
      status: status ?? this.status,
      taskId: taskId ?? this.taskId,
      action: action ?? this.action,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
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

  Future<void> submitAIAction(String action, Map<String, dynamic> data) async {
    state = state.copyWith(
      status: AIStatus.loading,
      action: action,
      errorMessage: null,
      result: null,
    );

    try {
      final normalizedAction = action.replaceAll('_', '-');
      final response = await _dio.post('ai/$normalizedAction/', data: data);
      final result = response.data;
      _applyResultToForm(action, result);

      final displayResult = _extractDisplayString(action, result);
      state = state.copyWith(
        status: AIStatus.success,
        result: displayResult,
        taskId: null,
      );
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response!.data as Map).toString()
          : e.message;
      state = state.copyWith(status: AIStatus.error, errorMessage: detail);
    } catch (e) {
      state = state.copyWith(
        status: AIStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Extracts a human-readable string from the task result for the result screen.
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

  void reset() {
    state = AIState();
  }

  /// Applies the completed AI result directly into the resume form state.
  void _applyResultToForm(String? action, dynamic result) {
    if (action == null || result == null) return;

    final form = _ref.read(resumeFormProvider.notifier);
    final response = result is Map ? result : <String, dynamic>{};

    switch (action) {
      case 'generate_summary':
        final summary = response['summary']?.toString();
        if (summary != null && summary.isNotEmpty) {
          form.updateSummary(summary);
        }
        break;
      case 'improve_section':
        final improved = response['improved_text']?.toString();
        if (improved != null && improved.isNotEmpty) {
          form.updateSummary(improved);
        }
        break;
      case 'suggest_skills':
        final skills = response['skills'] is List
            ? List<String>.from(response['skills'] as List)
            : <String>[];
        for (final skill in skills) {
          form.addSkill(skill);
        }
        break;
      case 'generate_bullets':
        final bullets = response['bullets'] is List
            ? List<String>.from(response['bullets'] as List)
            : <String>[];

        if (bullets.isEmpty) return;

        if (form.experienceItems.isEmpty) {
          form.addExperience();
        }
        final items = form.experienceItems;
        if (items.isEmpty) return;
        final first = Map<String, dynamic>.from(items.first);
        final existing = List<String>.from(
          first['bullets'] as List? ?? const [],
        );
        existing.addAll(bullets);
        first['bullets'] = existing;
        form.updateExperience(0, first);
        break;
      default:
        break;
    }
  }

}
