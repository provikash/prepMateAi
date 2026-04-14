import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepmate_mobile/features/resume/data/resume_api.dart';
import 'package:prepmate_mobile/features/resume/data/models/canvas_element.dart';
import 'package:prepmate_mobile/features/resume/data/models/resume.dart';

// 1. The Provider for Resume List
final resumeListProvider =
    AsyncNotifierProvider<ResumeListNotifier, List<Resume>>(
      () => ResumeListNotifier(),
    );

// 2. The AsyncNotifier for Resume List
class ResumeListNotifier extends AsyncNotifier<List<Resume>> {
  ResumeApi get _api => ref.read(resumeApiProvider);

  @override
  Future<List<Resume>> build() async {
    return await _api.getResumes();
  }
  // Future<List<Resume>> fetchResume() async {
  //   return await _api.getResumes();
  // }

  Future<Resume?> createResume({
    required String title,
    required List<CanvasElement> elements,
  }) async {
    try {
      final canvasData = elements.map((e) => e.toJson()).toList();
      final newResume = await _api.createResume(
        title: title,
        canvasData: canvasData,
      );

      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newResume]);
      }
      return newResume;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<void> updateResume({
    required int id,
    String? title,
    List<CanvasElement>? elements,
  }) async {
    try {
      List<Map<String, dynamic>>? canvasData;
      if (elements != null) {
        canvasData = elements.map((e) => e.toJson()).toList();
      }

      await _api.updateResume(id: id, title: title, canvasData: canvasData);
      ref.invalidateSelf();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteResume(int id) async {
    try {
      await _api.deleteResume(id);
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((r) => r.id != id).toList());
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// 3. The Notifier for the Active Canvas (CanvasElement list)
final canvasProvider =
    StateNotifierProvider.family<CanvasNotifier, List<CanvasElement>, int>((
      ref,
      resumeId,
    ) {
      final resumesAsync = ref.watch(resumeListProvider);

      return resumesAsync.when(
        data: (resumes) {
          final resume = resumes.firstWhere(
            (r) => r.id == resumeId,
            orElse: () => Resume(id: resumeId, title: '', canvasData: []),
          );

          final List<dynamic> rawData = resume.canvasData;
          final elements = rawData
              .map((e) => CanvasElement.fromJson(e as Map<String, dynamic>))
              .toList();
          return CanvasNotifier(elements);
        },
        loading: () => CanvasNotifier([]),
        error: (_, __) => CanvasNotifier([]),
      );
    });

class CanvasNotifier extends StateNotifier<List<CanvasElement>> {
  CanvasNotifier(super.state);

  void addElement(CanvasElement element) {
    state = [...state, element];
  }

  void updatePosition(String id, double newX, double newY) {
    state = [
      for (final element in state)
        if (element.id == id) element.copyWith(x: newX, y: newY) else element,
    ];
  }

  void updateElement(
    String id, {
    double? x,
    double? y,
    String? text,
    double? fontSize,
  }) {
    state = [
      for (final element in state)
        if (element.id == id)
          element.copyWith(
            x: x ?? element.x,
            y: y ?? element.y,
            text: text ?? element.text,
            fontSize: fontSize ?? element.fontSize,
          )
        else
          element,
    ];
  }

  void removeElement(String id) {
    state = state.where((e) => e.id != id).toList();
  }
}
