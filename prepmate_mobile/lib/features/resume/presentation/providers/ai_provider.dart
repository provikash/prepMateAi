import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../config/dio_client.dart';
import '../../../../../core/providers/form_provider.dart';

enum AIStatus { initial, loading, polling, success, error }

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
  Timer? _pollingTimer;

  AINotifier(this._ref, this._dio) : super(AIState());

  Future<void> submitAIAction(String action, Map<String, dynamic> data) async {
    state = state.copyWith(status: AIStatus.loading, errorMessage: null);

    try {
      // Convert action name from underscore to hyphen: generate_summary → generate-summary
      final normalizedAction = action.replaceAll('_', '-');
      final response = await _dio.post('ai/$normalizedAction/', data: data);
      final taskId = response.data['task_id'] as String?;

      if (taskId == null) {
        state = state.copyWith(
          status: AIStatus.error,
          errorMessage: 'No task ID returned from server.',
        );
        return;
      }

      state = state.copyWith(
        status: AIStatus.polling,
        taskId: taskId,
        action: action,
      );
      _startPolling(taskId);
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

  void _startPolling(String taskId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final response = await _dio.get('ai/tasks/$taskId/');
        final data = response.data as Map<String, dynamic>;
        // Celery task states: PENDING → STARTED → SUCCESS/FAILURE
        // Our backend returns lowercase: 'success', 'failure', 'pending', etc.
        final taskStatus = (data['status'] as String? ?? '').toLowerCase();

        if (taskStatus == 'success') {
          timer.cancel();
          final result = data['result'];
          // Apply result directly into the resume form
          _applyResultToForm(state.action, result);
          // Compute a clean string representation for the result screen
          final displayResult = _extractDisplayString(state.action, result);
          state = state.copyWith(
            status: AIStatus.success,
            result: displayResult,
          );
        } else if (taskStatus == 'failure' || taskStatus == 'failed') {
          timer.cancel();
          state = state.copyWith(
            status: AIStatus.error,
            errorMessage: data['error']?.toString() ?? 'AI generation failed.',
          );
        }
        // For 'pending' / 'started' / 'retry' — keep polling.
      } catch (e) {
        timer.cancel();
        state = state.copyWith(
          status: AIStatus.error,
          errorMessage: e.toString(),
        );
      }
    });
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
    _pollingTimer?.cancel();
    state = AIState();
  }

  /// Applies the completed AI result directly into the resume form state.
  void _applyResultToForm(String? action, dynamic result) {
    if (action == null || result == null) return;

    final form = _ref.read(resumeFormProvider.notifier);

    switch (action) {
      case 'generate_summary':
        final summary = result is Map
            ? result['summary']?.toString()
            : result.toString();
        if (summary != null && summary.isNotEmpty) {
          form.updateSummary(summary);
        }

      case 'improve_section':
        final improved = result is Map
            ? result['improved_text']?.toString()
            : result.toString();
        if (improved != null && improved.isNotEmpty) {
          form.updateSummary(improved);
        }

      case 'suggest_skills':
        final skills = result is Map && result['skills'] is List
            ? List<String>.from(result['skills'] as List)
            : result is List
            ? List<String>.from(result)
            : <String>[];
        for (final skill in skills) {
          form.addSkill(skill);
        }

      case 'generate_bullets':
        final bullets = result is Map && result['bullets'] is List
            ? List<String>.from(result['bullets'] as List)
            : result is List
            ? List<String>.from(result)
            : <String>[];

        if (bullets.isEmpty) return;

        // Append bullets to the first experience entry, adding one if empty.
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
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
