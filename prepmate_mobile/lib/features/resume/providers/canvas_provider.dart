import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepmate_mobile/config/dio_client.dart';
import '../data/models/canvas_element.dart';
import 'package:uuid/uuid.dart';

/// The Notifier class that holds the logic
final canvasProvider = NotifierProvider<CanvasNotifier, List<CanvasElement>>(
  CanvasNotifier.new,
);

class CanvasNotifier extends Notifier<List<CanvasElement>> {
  String? _currentResumeId;

  @override
  List<CanvasElement> build() {
    // initial state is an empty canvas
    return [];
  }

  // Load Template into local
  Future<void> loadTemplateFromBackend(String templateId) async {
    final dio = ref.read(dioProvider);

    try {
      // fetch master template JSON
      final response = await dio.get('/templates/$templateId');
      final List<dynamic> rawData = response.data['canvas_data'];

      /// Clone data and assign new uuids
      final List<CanvasElement> clonedElements = rawData.map((json) {
        final element = CanvasElement.fromJson(json as Map<String, dynamic>);
        return element.copyWith(id: const Uuid().v4());
      }).toList();

      _currentResumeId = null;
      state = clonedElements;
    } catch (e) {
      debugPrint("Failed to load template: $e");
    }
  }

  /////// Local Editing

  // Action: User taps "Add Text" in toolbar
  void addTextElement(String text, double startX, double startY) {
    final newElement = CanvasElement(
      id: const Uuid().v4(),
      text: text,
      x: startX,
      y: startY,
    );
    state = [...state, newElement];
  }

  void updatePosition(String id, double newX, double newY) {
    state = [
      for (final element in state)
        if (element.id == id) element.copyWith(x: newX, y: newY) else element,
    ];
  }

  // Action: User double taps and types new text (auto zoom)
  void updateText(String id, String newText) {
    state = [
      for (final element in state)
        if (element.id == id) element.copyWith(text: newText) else element,
    ];
  }

  // Action: Load data fetched via from Django
  void loadCanvasData(List<CanvasElement> serverData) {
    state = serverData;
  }

  /// Final save to server
  Future<bool> saveToServer() async {
    final dio = ref.read(dioProvider);

    final canvasDataJson = state.map((e) => e.toJson()).toList();
    final payload = {'title': 'My New Resume', 'canvas_data': canvasDataJson};

    try {
      if (_currentResumeId == null) {
        final response = await dio.post('/resumes/', data: payload);
        _currentResumeId = response.data['id'].toString();
      } else {
        await dio.patch('/resume/$_currentResumeId/', data: payload);
      }
      return true;
    } catch (e) {
      debugPrint("Save failed: $e");
      return false;
    }
  }
}
