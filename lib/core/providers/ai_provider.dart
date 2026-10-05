// import 'dart:async';
//
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:dio/dio.dart';
// import '../services/ai_service.dart';
// import 'form_provider.dart';
// import '../../config/dio_client.dart' show dioProvider;
//
// class AIState {
//   final String? taskId;
//   final String status;
//   final dynamic result;
//
//   AIState({this.taskId, this.status = 'idle', this.result});
//
//   AIState copyWith({String? taskId, String? status, dynamic result}) {
//     return AIState(
//       taskId: taskId ?? this.taskId,
//       status: status ?? this.status,
//       result: result ?? this.result,
//     );
//   }
// }
//
// class AINotifier extends StateNotifier<AIState> {
//   final Ref ref;
//   final AIService service;
//   Timer? _pollTimer;
//
//   AINotifier(this.ref, this.service) : super(AIState());
//
//   Future<void> submit(String action, Map<String, dynamic> payload) async {
//     state = state.copyWith(status: 'submitting');
//     final taskId = await service.submit(action, payload);
//     state = state.copyWith(taskId: taskId, status: 'queued', result: null);
//     _startPolling(taskId);
//   }
//
//   void _startPolling(String taskId) {
//     _pollTimer?.cancel();
//     _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
//       try {
//         final data = await service.getTask(taskId);
//         final status = (data['status'] ?? '').toString().toLowerCase();
//         if (status == 'failed') {
//           state = state.copyWith(status: 'failed', result: data['error']);
//           _pollTimer?.cancel();
//         } else if (status == 'ready' || status == 'success' || data.containsKey('result')) {
//           state = state.copyWith(status: 'ready', result: data['result']);
//           _pollTimer?.cancel();
//         } else {
//           state = state.copyWith(status: status);
//         }
//       } catch (e) {
//         state = state.copyWith(status: 'error', result: e.toString());
//       }
//     });
//   }
//
//   void stopPolling() {
//     _pollTimer?.cancel();
//   }
//
//   void applyToResume(String action) {
//     // action-specific apply logic: merge result into resume form
//     final form = ref.read(resumeFormProvider.notifier);
//     final res = state.result;
//     if (res == null) return;
//     if (action == 'generate-summary' && res is Map && res['summary'] != null) {
//       form.updateSummary(res['summary'] as String);
//     }
//     if (action == 'improve-section' && res is Map && res['improved_text'] != null) {
//       form.updateSummary(res['improved_text'] as String);
//     }
//     if (action == 'suggest-skills' && res is Map && res['skills'] is List) {
//       final skills = List<String>.from(res['skills'] as List);
//       for (final s in skills) form.addSkill(s);
//     }
//     if (action == 'generate-bullets' && res is Map && res['bullets'] is List) {
//       // append bullets to the first experience if exists
//       final bullets = List<String>.from(res['bullets'] as List);
//       final formState = ref.read(resumeFormProvider);
//       final exp = List<Map<String, dynamic>>.from(formState.data['experience'] as List);
//       if (exp.isNotEmpty) {
//         final first = Map<String, dynamic>.from(exp[0]);
//         final existing = List<String>.from(first['bullets'] ?? <String>[]);
//         existing.addAll(bullets);
//         first['bullets'] = existing;
//         form.updateExperience(0, first);
//       }
//     }
//   }
// }
//
// final aiProvider = StateNotifierProvider<AINotifier, AIState>((ref) {
//   final dio = ref.read(dioProvider);
//   final service = AIService(dio);
//   return AINotifier(ref, service);
// });
