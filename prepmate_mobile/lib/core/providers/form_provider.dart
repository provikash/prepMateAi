import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResumeFormState {
  final Map<String, dynamic> data;
  final Set<String> visibleSections;
  final Map<String, List<String>> sectionActions;

  Map<String, dynamic> get basics =>
      Map<String, dynamic>.from(data['basics'] as Map? ?? const {});

  List<Map<String, dynamic>> get experienceItems =>
      List<Map<String, dynamic>>.from(data['experience'] as List? ?? const []);

  List<String> get skills => List<String>.from(data['skills'] as List? ?? const []);

  String get summary => data['summary'] as String? ?? '';

  Map<String, dynamic> sectionMap(String key) =>
    Map<String, dynamic>.from(data[key] as Map? ?? const {});

  List<Map<String, dynamic>> sectionItems(String key) =>
    List<Map<String, dynamic>>.from(data[key] as List? ?? const []);

  const ResumeFormState({
    required this.data,
    this.visibleSections = const {'basics', 'summary', 'experience', 'skills'},
    this.sectionActions = const {},
  });

  ResumeFormState copyWith({
    Map<String, dynamic>? data,
    Set<String>? visibleSections,
    Map<String, List<String>>? sectionActions,
  }) {
    return ResumeFormState(
      data: data ?? this.data,
      visibleSections: visibleSections ?? this.visibleSections,
      sectionActions: sectionActions ?? this.sectionActions,
    );
  }
}

class ResumeFormNotifier extends StateNotifier<ResumeFormState> {
  ResumeFormNotifier()
    : super(
        const ResumeFormState(
          data: {
            'basics': {'name': '', 'email': '', 'phone': '', 'label': ''},
            'summary': '',
            'experience': <Map<String, dynamic>>[],
            'skills': <String>[],
          },
        ),
      );

  Map<String, dynamic> get basics =>
      Map<String, dynamic>.from(state.data['basics'] as Map? ?? const {});

  List<Map<String, dynamic>> get experienceItems =>
      List<Map<String, dynamic>>.from(
        state.data['experience'] as List? ?? const [],
      );

  List<String> get skills =>
      List<String>.from(state.data['skills'] as List? ?? const []);

    Map<String, dynamic> sectionMap(String key) =>
      Map<String, dynamic>.from(state.data[key] as Map? ?? const {});

    List<Map<String, dynamic>> sectionItems(String key) =>
      List<Map<String, dynamic>>.from(state.data[key] as List? ?? const []);

  void applySchema({
    required Set<String> visibleSections,
    required Map<String, List<String>> sectionActions,
  }) {
    state = state.copyWith(
      visibleSections: visibleSections,
      sectionActions: sectionActions,
    );
  }

  void updateBasics(Map<String, dynamic> patch) {
    final current = basics;
    current.addAll(patch);
    final nextData = Map<String, dynamic>.from(state.data);
    nextData['basics'] = current;
    state = state.copyWith(data: nextData);
  }

  void updateBasicField(String key, String value) => updateBasics({key: value});

  void updateSummary(String text) {
    final nextData = Map<String, dynamic>.from(state.data);
    nextData['summary'] = text;
    state = state.copyWith(data: nextData);
  }

  void updateSectionField(String sectionKey, String fieldKey, dynamic value) {
    final nextData = Map<String, dynamic>.from(state.data);
    final section = sectionMap(sectionKey);
    section[fieldKey] = value;
    nextData[sectionKey] = section;
    state = state.copyWith(data: nextData);
  }

  void addSectionItem(String sectionKey, Map<String, dynamic> item) {
    final nextData = Map<String, dynamic>.from(state.data);
    final items = sectionItems(sectionKey);
    items.add(Map<String, dynamic>.from(item));
    nextData[sectionKey] = items;
    state = state.copyWith(data: nextData);
  }

  void updateSectionItem(String sectionKey, int index, Map<String, dynamic> patch) {
    final items = sectionItems(sectionKey);
    if (index < 0 || index >= items.length) return;
    final item = Map<String, dynamic>.from(items[index]);
    item.addAll(patch);
    items[index] = item;
    final nextData = Map<String, dynamic>.from(state.data);
    nextData[sectionKey] = items;
    state = state.copyWith(data: nextData);
  }

  void removeSectionItem(String sectionKey, int index) {
    final items = sectionItems(sectionKey);
    if (index < 0 || index >= items.length) return;
    items.removeAt(index);
    final nextData = Map<String, dynamic>.from(state.data);
    nextData[sectionKey] = items;
    state = state.copyWith(data: nextData);
  }

  void addExperience([Map<String, dynamic>? item]) {
    final list = experienceItems;
    list.add(
      item ??
          {
            'title': '',
            'company': '',
            'location': '',
            'startDate': '',
            'endDate': '',
            'summary': '',
            'bullets': <String>[],
          },
    );
    final nextData = Map<String, dynamic>.from(state.data);
    nextData['experience'] = list;
    state = state.copyWith(data: nextData);
  }

  void updateExperience(int index, Map<String, dynamic> patch) {
    final list = experienceItems;
    if (index < 0 || index >= list.length) return;
    final item = Map<String, dynamic>.from(list[index]);
    item.addAll(patch);
    list[index] = item;
    final nextData = Map<String, dynamic>.from(state.data);
    nextData['experience'] = list;
    state = state.copyWith(data: nextData);
  }

  void removeExperience(int index) {
    final list = experienceItems;
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    final nextData = Map<String, dynamic>.from(state.data);
    nextData['experience'] = list;
    state = state.copyWith(data: nextData);
  }

  void addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty) return;
    final list = skills;
    if (!list.contains(trimmed)) {
      list.add(trimmed);
      final nextData = Map<String, dynamic>.from(state.data);
      nextData['skills'] = list;
      state = state.copyWith(data: nextData);
    }
  }

  void removeSkill(String skill) {
    final list = skills;
    list.remove(skill);
    final nextData = Map<String, dynamic>.from(state.data);
    nextData['skills'] = list;
    state = state.copyWith(data: nextData);
  }

  void replaceSkills(List<String> values) {
    final nextData = Map<String, dynamic>.from(state.data);
    nextData['skills'] = values
        .where((value) => value.trim().isNotEmpty)
        .toList();
    state = state.copyWith(data: nextData);
  }
}

final resumeFormProvider =
    StateNotifierProvider<ResumeFormNotifier, ResumeFormState>((ref) {
      return ResumeFormNotifier();
    });
