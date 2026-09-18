import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResumeFormState {
  final Map<String, dynamic> data;
  final Set<String> visibleSections;
  final Map<String, List<String>> sectionActions;
  final int revision;

  Map<String, dynamic> get basics =>
      Map<String, dynamic>.from(data['basics'] as Map? ?? const {});

  List<Map<String, dynamic>> get experienceItems =>
      List<Map<String, dynamic>>.from(
        data['work'] as List? ?? data['experience'] as List? ?? const [],
      );

  List<String> get skills {
    final raw = data['skills'];
    if (raw is List) {
      return raw
          .map((e) => e is Map ? (e['name']?.toString() ?? '') : e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String get summary =>
      (data['basics'] as Map?)?['summary'] as String? ??
      data['summary'] as String? ??
      '';

  Map<String, dynamic> sectionMap(String key) =>
      Map<String, dynamic>.from(data[key] as Map? ?? const {});

  List<Map<String, dynamic>> sectionItems(String key) =>
      List<Map<String, dynamic>>.from(data[key] as List? ?? const []);

  const ResumeFormState({
    required this.data,
    this.visibleSections = const {'basics', 'summary', 'experience', 'skills'},
    this.sectionActions = const {},
    this.revision = 0,
  });

  ResumeFormState copyWith({
    Map<String, dynamic>? data,
    Set<String>? visibleSections,
    Map<String, List<String>>? sectionActions,
    int? revision,
  }) {
    return ResumeFormState(
      data: data ?? this.data,
      visibleSections: visibleSections ?? this.visibleSections,
      sectionActions: sectionActions ?? this.sectionActions,
      revision: revision ?? this.revision,
    );
  }
}

class ResumeFormNotifier extends StateNotifier<ResumeFormState> {
  ResumeFormNotifier()
    : super(
        const ResumeFormState(
          data: {
            // JSON Resume standard schema
            'basics': {
              'name': '',
              'label': '',
              'email': '',
              'phone': '',
              'summary': '',
              'location': {'city': ''},
              'profiles': <Map<String, dynamic>>[],
            },
            'work': <Map<String, dynamic>>[],
            'education': <Map<String, dynamic>>[],
            'projects': <Map<String, dynamic>>[],
            'skills': <Map<String, dynamic>>[],
          },
        ),
      );

  void restoreData(Map<String, dynamic> data) {
    state = state.copyWith(
      data: Map<String, dynamic>.from(data),
      revision: state.revision + 1,
    );
  }

  Map<String, dynamic> get basics =>
      Map<String, dynamic>.from(state.data['basics'] as Map? ?? const {});

  List<Map<String, dynamic>> get experienceItems =>
      List<Map<String, dynamic>>.from(
        state.data['work'] as List? ??
            state.data['experience'] as List? ??
            const [],
      );

  List<String> get skills {
    final raw = state.data['skills'];
    if (raw is List) {
      return raw
          .map((e) => e is Map ? (e['name']?.toString() ?? '') : e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

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
    state = state.copyWith(data: nextData, revision: state.revision + 1);
  }

  void updateBasicField(String key, String value) => updateBasics({key: value});

  void updateSummary(String text) {
    // Store summary inside basics as per JSON Resume schema.
    final current = basics;
    current['summary'] = text;
    final nextData = Map<String, dynamic>.from(state.data);
    nextData['basics'] = current;
    state = state.copyWith(data: nextData, revision: state.revision + 1);
  }

  void updateSectionField(String sectionKey, String fieldKey, dynamic value) {
    final nextData = Map<String, dynamic>.from(state.data);
    final section = sectionMap(sectionKey);
    section[fieldKey] = value;
    nextData[sectionKey] = section;
    state = state.copyWith(data: nextData, revision: state.revision + 1);
  }

  void addSectionItem(String sectionKey, Map<String, dynamic> item) {
    final nextData = Map<String, dynamic>.from(state.data);
    final items = sectionItems(sectionKey);
    items.add(Map<String, dynamic>.from(item));
    nextData[sectionKey] = items;
    state = state.copyWith(data: nextData, revision: state.revision + 1);
  }

  void updateSectionItem(
    String sectionKey,
    int index,
    Map<String, dynamic> patch,
  ) {
    final items = sectionItems(sectionKey);
    if (index < 0 || index >= items.length) return;
    final item = Map<String, dynamic>.from(items[index]);
    item.addAll(patch);
    items[index] = item;
    final nextData = Map<String, dynamic>.from(state.data);
    nextData[sectionKey] = items;
    state = state.copyWith(data: nextData, revision: state.revision + 1);
  }

  void removeSectionItem(String sectionKey, int index) {
    final items = sectionItems(sectionKey);
    if (index < 0 || index >= items.length) return;
    items.removeAt(index);
    final nextData = Map<String, dynamic>.from(state.data);
    nextData[sectionKey] = items;
    state = state.copyWith(data: nextData, revision: state.revision + 1);
  }

  void clearSection(String sectionKey) {
    final nextData = Map<String, dynamic>.from(state.data);
    nextData[sectionKey] = <Map<String, dynamic>>[];
    state = state.copyWith(data: nextData, revision: state.revision + 1);
  }

  /// Removes placeholder rows before sync so partially opened repeatable cards
  /// never become invalid server records. Existing value types and null end
  /// dates are preserved.
  void sanitizeForSubmission() {
    final sanitized = <String, dynamic>{};
    for (final entry in state.data.entries) {
      sanitized[entry.key] = _sanitizeValue(entry.value);
    }
    state = state.copyWith(data: sanitized, revision: state.revision + 1);
  }

  void reorderSectionItem(String sectionKey, int from, int to) {
    final items = sectionItems(sectionKey);
    if (from < 0 || from >= items.length || to < 0 || to >= items.length) {
      return;
    }
    final item = items.removeAt(from);
    items.insert(to, item);
    final nextData = Map<String, dynamic>.from(state.data);
    nextData[sectionKey] = items;
    state = state.copyWith(data: nextData, revision: state.revision + 1);
  }

  void addExperience([Map<String, dynamic>? item]) {
    final list = experienceItems;
    list.add(
      item ??
          {
            'position': '',
            'name': '', // company name per JSON Resume
            'startDate': '',
            'endDate': '',
            'summary': '',
            'highlights': <String>[],
          },
    );
    final nextData = Map<String, dynamic>.from(state.data);
    // Store in `work` (JSON Resume standard key).
    nextData['work'] = list;
    state = state.copyWith(data: nextData, revision: state.revision + 1);
  }

  void updateExperience(int index, Map<String, dynamic> patch) {
    final list = experienceItems;
    if (index < 0 || index >= list.length) return;
    final item = Map<String, dynamic>.from(list[index]);
    item.addAll(patch);
    list[index] = item;
    final nextData = Map<String, dynamic>.from(state.data);
    nextData['work'] = list;
    state = state.copyWith(data: nextData, revision: state.revision + 1);
  }

  void removeExperience(int index) {
    final list = experienceItems;
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    final nextData = Map<String, dynamic>.from(state.data);
    nextData['work'] = list;
    state = state.copyWith(data: nextData, revision: state.revision + 1);
  }

  void addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty) return;
    final raw = state.data['skills'];
    final List<dynamic> list = raw is List ? List<dynamic>.from(raw) : [];
    // Support both plain string list and {name, keywords} object list.
    final names = list
        .map((e) => e is Map ? e['name']?.toString() ?? '' : e.toString())
        .toList();
    if (!names.contains(trimmed)) {
      list.add({'name': trimmed, 'level': '', 'keywords': <String>[]});
      final nextData = Map<String, dynamic>.from(state.data);
      nextData['skills'] = list;
      state = state.copyWith(data: nextData, revision: state.revision + 1);
    }
  }

  void removeSkill(String skill) {
    final raw = state.data['skills'];
    if (raw is! List) return;
    final list = List<dynamic>.from(raw);
    list.removeWhere((e) {
      final name = e is Map ? e['name']?.toString() ?? '' : e.toString();
      return name == skill;
    });
    final nextData = Map<String, dynamic>.from(state.data);
    nextData['skills'] = list;
    state = state.copyWith(data: nextData, revision: state.revision + 1);
  }

  void replaceSkills(List<String> values) {
    final nextData = Map<String, dynamic>.from(state.data);
    nextData['skills'] = values
        .where((value) => value.trim().isNotEmpty)
        .map((name) => {'name': name, 'level': '', 'keywords': <String>[]})
        .toList();
    state = state.copyWith(data: nextData, revision: state.revision + 1);
  }

  /// Pre-fills the basics section from the authenticated user's profile.
  /// Only sets fields that are currently empty so it doesn't overwrite
  /// anything the user has already typed.
  void prefillFromProfile(Map<String, dynamic> profile) {
    final current = basics;
    final patch = <String, dynamic>{};

    void setIfEmpty(String key, dynamic value) {
      final existing = current[key];
      if ((existing == null || existing.toString().trim().isEmpty) &&
          value != null &&
          value.toString().trim().isNotEmpty) {
        patch[key] = value.toString().trim();
      }
    }

    // Both `name` and `full_name` keys are checked for compatibility.
    setIfEmpty('name', profile['full_name'] ?? profile['name']);
    setIfEmpty('email', profile['email']);
    setIfEmpty('phone', profile['phone'] ?? profile['phone_number']);
    // location is stored as a nested {city: ''} object in JSON Resume.
    final locationVal = profile['location'] ?? profile['city'];
    if (locationVal != null && locationVal.toString().trim().isNotEmpty) {
      final existingLoc = current['location'];
      final existingCity = existingLoc is Map
          ? (existingLoc['city']?.toString() ?? '')
          : (existingLoc?.toString() ?? '');
      if (existingCity.trim().isEmpty) {
        patch['location'] = {'city': locationVal.toString().trim()};
      }
    }
    setIfEmpty('label', profile['job_title'] ?? profile['title']);
    setIfEmpty('summary', profile['bio'] ?? profile['summary']);
    setIfEmpty('url', profile['website'] ?? profile['url']);

    if (patch.isNotEmpty) {
      updateBasics(patch);
    }

    // Also mirror linkedin/github into the profiles array if empty.
    _prefillSocialProfiles(profile);
  }

  void _prefillSocialProfiles(Map<String, dynamic> profile) {
    final nextData = Map<String, dynamic>.from(state.data);
    final basicsMap = Map<String, dynamic>.from(
      nextData['basics'] as Map? ?? {},
    );
    final profiles = List<dynamic>.from(basicsMap['profiles'] as List? ?? []);

    void addProfileIfMissing(String network, String? url) {
      if (url == null || url.trim().isEmpty) return;
      final alreadyExists = profiles.any(
        (p) =>
            p is Map &&
            (p['network'] as String? ?? '').toLowerCase() ==
                network.toLowerCase(),
      );
      if (!alreadyExists) {
        profiles.add({'network': network, 'username': url, 'url': url});
      }
    }

    addProfileIfMissing('LinkedIn', profile['linkedin']);
    addProfileIfMissing('GitHub', profile['github']);

    basicsMap['profiles'] = profiles;
    nextData['basics'] = basicsMap;
    state = state.copyWith(data: nextData, revision: state.revision + 1);
  }
}

final resumeFormProvider =
    StateNotifierProvider<ResumeFormNotifier, ResumeFormState>((ref) {
      return ResumeFormNotifier();
    });

dynamic _sanitizeValue(dynamic value) {
  if (value is List) {
    return value
        .map(_sanitizeValue)
        .where(_hasMeaningfulValue)
        .toList(growable: true);
  }
  if (value is Map) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key.toString(): _sanitizeValue(entry.value),
    };
  }
  return value;
}

bool _hasMeaningfulValue(dynamic value) {
  if (value == null) return false;
  if (value is String) return value.trim().isNotEmpty;
  if (value is List) return value.any(_hasMeaningfulValue);
  if (value is Map) return value.values.any(_hasMeaningfulValue);
  return true;
}
