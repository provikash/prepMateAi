import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/resume_remote_data_source.dart';
import 'resume_providers.dart';

final resumeFormStateProvider =
    StateNotifierProvider.autoDispose<
      ResumeFormStateNotifier,
      Map<String, Map<String, dynamic>>
    >((ref) {
      return ResumeFormStateNotifier();
    });

class ResumeFormStateNotifier
    extends StateNotifier<Map<String, Map<String, dynamic>>> {
  ResumeFormStateNotifier() : super({});

  void initialize(Map<String, dynamic> initialData) {
    final Map<String, Map<String, dynamic>> newState = {};
    for (final entry in initialData.entries) {
      if (entry.value is Map) {
        newState[entry.key] = Map<String, dynamic>.from(entry.value);
      } else {
        newState[entry.key] = {'items': entry.value};
      }
    }
    state = newState;
  }

  void updateField(String sectionKey, String fieldKey, dynamic value) {
    final currentSection = Map<String, dynamic>.from(state[sectionKey] ?? {});
    currentSection[fieldKey] = value;
    state = {...state, sectionKey: currentSection};
  }

  void updateRepeatableItemField(
    String sectionKey,
    int index,
    String fieldKey,
    dynamic value,
  ) {
    final currentSection = Map<String, dynamic>.from(state[sectionKey] ?? {});
    final items = List<dynamic>.from(currentSection['items'] ?? []);
    if (index >= 0 && index < items.length) {
      final item = Map<String, dynamic>.from(items[index] ?? {});
      item[fieldKey] = value;
      items[index] = item;
      currentSection['items'] = items;
      state = {...state, sectionKey: currentSection};
    }
  }

  void addRepeatableItem(String sectionKey, Map<String, dynamic> item) {
    final currentSection = Map<String, dynamic>.from(state[sectionKey] ?? {});
    final items = List<dynamic>.from(currentSection['items'] ?? []);
    items.add(item);
    currentSection['items'] = items;
    state = {...state, sectionKey: currentSection};
  }

  void removeRepeatableItem(String sectionKey, int index) {
    final currentSection = Map<String, dynamic>.from(state[sectionKey] ?? {});
    final items = List<dynamic>.from(currentSection['items'] ?? []);
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      currentSection['items'] = items;
      state = {...state, sectionKey: currentSection};
    }
  }

  void addSkill(String sectionKey, String skill) {
    final currentSection = Map<String, dynamic>.from(state[sectionKey] ?? {});
    final items = List<dynamic>.from(currentSection['items'] ?? []);
    items.add(skill);
    currentSection['items'] = items;
    state = {...state, sectionKey: currentSection};
  }

  void removeSkill(String sectionKey, int index) {
    final currentSection = Map<String, dynamic>.from(state[sectionKey] ?? {});
    final items = List<dynamic>.from(currentSection['items'] ?? []);
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      currentSection['items'] = items;
      state = {...state, sectionKey: currentSection};
    }
  }
}
