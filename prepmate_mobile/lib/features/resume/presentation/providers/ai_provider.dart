import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
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
      // Convert action name from underscore to hyphen (e.g., generate_summary -> generate-summary)
      final normalizedAction = action.replaceAll('_', '-');
      final response = await _dio.post('/ai/$normalizedAction/', data: data);
      final taskId = response.data['task_id'];

      state = state.copyWith(
        status: AIStatus.polling,
        taskId: taskId,
        action: action,
      );
      _startPolling(taskId);
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
        final response = await _dio.get('/ai/task/$taskId/');
        final status = response.data['status'];

        if (status == 'completed') {
          timer.cancel();
          final result = response.data['result'];
          _applyResultToForm(state.action, result);
          state = state.copyWith(
            status: AIStatus.success,
            result: result?.toString(),
          );
        } else if (status == 'failed') {
          timer.cancel();
          state = state.copyWith(
            status: AIStatus.error,
            errorMessage: 'AI generation failed',
          );
        }
      } catch (e) {
        timer.cancel();
        state = state.copyWith(
          status: AIStatus.error,
          errorMessage: e.toString(),
        );
      }
    });
  }

  void reset() {
    _pollingTimer?.cancel();
    state = AIState();
  }

  void _applyResultToForm(String? action, dynamic result) {
    if (action == null || result == null) return;

    final form = _ref.read(resumeFormProvider.notifier);

    if (action == 'generate_summary') {
      if (result is Map && result['summary'] != null) {
        form.updateSummary(result['summary'].toString());
      } else {
        form.updateSummary(result.toString());
      }
      return;
    }

    if (action == 'improve_section') {
      if (result is Map && result['improved_text'] != null) {
        form.updateSummary(result['improved_text'].toString());
      } else {
        form.updateSummary(result.toString());
      }
      return;
    }

    if (action == 'suggest_skills') {
      final skills = result is Map && result['skills'] is List
          ? List<String>.from(result['skills'] as List)
          : result is List
          ? List<String>.from(result)
          : <String>[];
      for (final skill in skills) {
        form.addSkill(skill);
      }
      return;
    }

    if (action == 'generate_bullets') {
      final bullets = result is Map && result['bullets'] is List
          ? List<String>.from(result['bullets'] as List)
          : result is List
          ? List<String>.from(result)
          : <String>[];
      final items = form.experienceItems;
      if (items.isEmpty) {
        form.addExperience();
      }
      final current = form.experienceItems;
      if (current.isEmpty) return;
      final first = Map<String, dynamic>.from(current.first);
      final existing = List<String>.from(first['bullets'] as List? ?? const []);
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
