import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/viewmodel/auth_viewmodel.dart';

enum DraftSyncState { localOnly, syncing, synced, failed, conflict }

class ResumeDraft {
  const ResumeDraft({
    required this.localId,
    required this.userId,
    required this.templateId,
    required this.templateVersion,
    required this.data,
    required this.updatedAt,
    required this.syncState,
    this.remoteResumeId,
    this.remoteVersion,
  });

  final String localId;
  final String userId;
  final String templateId;
  final String templateVersion;
  final Map<String, dynamic> data;
  final DateTime updatedAt;
  final DraftSyncState syncState;
  final String? remoteResumeId;
  final String? remoteVersion;

  Map<String, dynamic> toJson() => {
    'schema_version': 1,
    'local_id': localId,
    'user_id': userId,
    'template_id': templateId,
    'template_version': templateVersion,
    'data': data,
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'sync_state': syncState.name,
    'remote_resume_id': remoteResumeId,
    'remote_version': remoteVersion,
  };

  static ResumeDraft? tryParse(String encoded) {
    try {
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic> || json['schema_version'] != 1) {
        return null;
      }
      return ResumeDraft(
        localId: json['local_id'] as String,
        userId: json['user_id'] as String,
        templateId: json['template_id'] as String,
        templateVersion: json['template_version'] as String? ?? '1',
        data: Map<String, dynamic>.from(json['data'] as Map),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        syncState: DraftSyncState.values.firstWhere(
          (value) => value.name == json['sync_state'],
          orElse: () => DraftSyncState.localOnly,
        ),
        remoteResumeId: json['remote_resume_id'] as String?,
        remoteVersion: json['remote_version'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

class ResumeDraftStore {
  static const _prefix = 'prepmate_draft_v1_';
  Future<SharedPreferences>? _preferences;

  Future<SharedPreferences> get _prefs =>
      _preferences ??= SharedPreferences.getInstance();

  String _key(String userId, String localId) => '$_prefix$userId:$localId';

  Future<ResumeDraft?> read(String userId, String localId) async {
    final prefs = await _prefs;
    final key = _key(userId, localId);
    final encoded = prefs.getString(key);
    if (encoded == null) return null;
    final draft = ResumeDraft.tryParse(encoded);
    if (draft == null || draft.userId != userId || draft.localId != localId) {
      await prefs.remove(key);
      return null;
    }
    return draft;
  }

  Future<void> write(ResumeDraft draft) async {
    await (await _prefs).setString(
      _key(draft.userId, draft.localId),
      jsonEncode(draft.toJson()),
    );
  }

  Future<void> delete(String userId, String localId) async {
    await (await _prefs).remove(_key(userId, localId));
  }

  Future<void> deleteForUser(String userId) async {
    final prefs = await _prefs;
    final prefix = '$_prefix$userId:';
    await Future.wait(
      prefs.getKeys().where((key) => key.startsWith(prefix)).map(prefs.remove),
    );
  }
}

class ResumeDraftController extends StateNotifier<DraftSyncState> {
  ResumeDraftController(this.store, this.userId)
    : super(DraftSyncState.localOnly);

  final ResumeDraftStore store;
  final String? Function() userId;
  Timer? _debounce;
  ResumeDraft? _pending;

  String localIdFor(String templateId, [String? remoteResumeId]) =>
      remoteResumeId == null || remoteResumeId.isEmpty
      ? 'template-$templateId'
      : 'resume-$remoteResumeId';

  Future<ResumeDraft?> restore({
    required String templateId,
    String? remoteResumeId,
  }) async {
    final user = userId();
    if (user == null) return null;
    final draft = await store.read(
      user,
      localIdFor(templateId, remoteResumeId),
    );
    if (draft != null) state = draft.syncState;
    return draft;
  }

  void schedule({
    required String templateId,
    required Map<String, dynamic> data,
    String templateVersion = '1',
    String? remoteResumeId,
    String? remoteVersion,
  }) {
    final user = userId();
    if (user == null) return;
    _pending = ResumeDraft(
      localId: localIdFor(templateId, remoteResumeId),
      userId: user,
      templateId: templateId,
      templateVersion: templateVersion,
      data: Map<String, dynamic>.from(data),
      updatedAt: DateTime.now(),
      syncState: DraftSyncState.localOnly,
      remoteResumeId: remoteResumeId,
      remoteVersion: remoteVersion,
    );
    state = DraftSyncState.localOnly;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), flush);
  }

  Future<void> flush() async {
    _debounce?.cancel();
    final draft = _pending;
    if (draft == null) return;
    try {
      await store.write(draft);
      state = DraftSyncState.localOnly;
    } catch (_) {
      state = DraftSyncState.failed;
    }
  }

  Future<void> markSynced({
    required String templateId,
    required String remoteResumeId,
  }) async {
    state = DraftSyncState.synced;
    final user = userId();
    if (user == null) return;
    final oldId = localIdFor(templateId);
    final pending = _pending;
    if (pending != null) {
      final synced = ResumeDraft(
        localId: localIdFor(templateId, remoteResumeId),
        userId: user,
        templateId: templateId,
        templateVersion: pending.templateVersion,
        data: pending.data,
        updatedAt: DateTime.now(),
        syncState: DraftSyncState.synced,
        remoteResumeId: remoteResumeId,
      );
      await store.write(synced);
      _pending = synced;
    }
    if (oldId != localIdFor(templateId, remoteResumeId)) {
      await store.delete(user, oldId);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final resumeDraftStoreProvider = Provider<ResumeDraftStore>((ref) {
  return ResumeDraftStore();
});

final resumeDraftControllerProvider =
    StateNotifierProvider<ResumeDraftController, DraftSyncState>((ref) {
      return ResumeDraftController(
        ref.watch(resumeDraftStoreProvider),
        () => ref.read(authViewModelProvider).user?.id,
      );
    });
