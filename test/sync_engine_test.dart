import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/core/database/app_database.dart';
import 'package:prepmate_mobile/core/sync/sync_engine.dart';
import 'package:prepmate_mobile/features/resume/data/datasources/resume_remote_data_source.dart';
import 'package:prepmate_mobile/features/resume/data/models/created_resume_model.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(executor: NativeDatabase.memory()));
  tearDown(() => database.close());

  test('guest workspace is stable and can be claimed by an account', () async {
    final guest = await database.activateWorkspace();
    final sameGuest = await database.activateWorkspace();

    expect(sameGuest.workspaceId, guest.workspaceId);
    expect(guest.accountId, isNull);

    final account = await database.activateWorkspace(accountId: 'user-1');
    expect(account.workspaceId, guest.workspaceId);
    expect(account.accountId, 'user-1');
  });

  test('returning account adopts resumes from the active guest', () async {
    final firstGuest = await database.activateWorkspace();
    final account = await database.activateWorkspace(accountId: 'user-1');
    expect(account.workspaceId, firstGuest.workspaceId);

    final secondGuest = await database.activateWorkspace();
    final now = DateTime(2026, 1, 1);
    await database
        .into(database.localResumes)
        .insert(
          LocalResumesCompanion.insert(
            localId: 'local-returning-user',
            workspaceId: Value(secondGuest.workspaceId),
            userId: secondGuest.workspaceId,
            payload: '{}',
            syncStatus: const Value('local_only'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final reactivated = await database.activateWorkspace(accountId: 'user-1');
    final resume = await database.readLocalResume('local-returning-user');
    expect(reactivated.workspaceId, account.workspaceId);
    expect(resume?.workspaceId, account.workspaceId);
  });

  test('local-only resumes are queued only after account login', () async {
    final workspace = await database.activateWorkspace();
    final now = DateTime(2026, 1, 1);
    await database
        .into(database.localResumes)
        .insert(
          LocalResumesCompanion.insert(
            localId: 'local-guest',
            workspaceId: Value(workspace.workspaceId),
            userId: workspace.workspaceId,
            payload: jsonEncode({
              'template_id': 'template-1',
              'title': 'Guest resume',
              'data': <String, dynamic>{},
              'draft': true,
            }),
            syncStatus: const Value('local_only'),
            createdAt: now,
            updatedAt: now,
          ),
        );

    expect(await database.select(database.mutationOutbox).get(), isEmpty);

    await database.queueWorkspaceResumesForSync(
      workspaceId: workspace.workspaceId,
      accountId: 'user-1',
    );

    final queued = await database.select(database.mutationOutbox).getSingle();
    expect(queued.userId, 'user-1');
    expect(queued.entityLocalId, 'local-guest');
    expect(
      (await database.readLocalResume('local-guest'))?.syncStatus,
      'pending',
    );
  });

  Future<void> stage({String status = 'pending', String? remoteId}) async {
    final now = DateTime(2026, 1, 1);
    final payload = jsonEncode({
      'template_id': 'template-1',
      'title': 'Local resume',
      'data': <String, dynamic>{},
      'draft': true,
    });
    await database
        .into(database.localResumes)
        .insert(
          LocalResumesCompanion.insert(
            localId: 'local-1',
            userId: 'user-1',
            remoteId: Value(remoteId),
            payload: payload,
            syncStatus: Value(status),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.mutationOutbox)
        .insert(
          MutationOutboxCompanion.insert(
            userId: 'user-1',
            entityType: 'resume',
            entityLocalId: 'local-1',
            operation: 'save',
            payload: payload,
            createdAt: now,
          ),
        );
  }

  test('successful sync resolves local id and clears the outbox', () async {
    await stage();
    final engine = SyncEngine(
      database: database,
      resumes: _FakeResumeRemote(),
      dio: Dio(),
    );

    final result = await engine.run(source: SyncRunSource.manual);

    expect(result.succeeded, isTrue);
    expect((await database.readLocalResume('local-1'))?.remoteId, 'remote-1');
    expect((await database.readLocalResume('local-1'))?.revision, 4);
    expect(await database.select(database.mutationOutbox).get(), isEmpty);
    expect(await database.select(database.syncEvents).get(), hasLength(1));
  });

  test('409 preserves an explicit conflict copy for review', () async {
    await stage();
    final engine = SyncEngine(
      database: database,
      resumes: _FakeResumeRemote(failure: ResumeSaveFailureKind.conflict),
      dio: Dio(),
    );

    await engine.run(source: SyncRunSource.foreground);

    final resumes = await database.select(database.localResumes).get();
    final outbox = await database.select(database.mutationOutbox).getSingle();
    expect(resumes, hasLength(2));
    expect(resumes.any((item) => item.conflictOf == 'local-1'), isTrue);
    expect(outbox.permanentFailure, isTrue);
  });

  test('connection failures are retryable with exponential delay', () async {
    await stage();
    final engine = SyncEngine(
      database: database,
      resumes: _FakeResumeRemote(failure: ResumeSaveFailureKind.connection),
      dio: Dio(),
    );

    final result = await engine.run(source: SyncRunSource.background);

    final outbox = await database.select(database.mutationOutbox).getSingle();
    expect(result.retryScheduled, isTrue);
    expect(outbox.attemptCount, 1);
    expect(outbox.nextAttemptAt, isNotNull);
    expect(outbox.permanentFailure, isFalse);
  });

  test(
    'a poisoned local remote id is sent as a create, not an update',
    () async {
      await stage(remoteId: 'local-1791609387889222');
      final remote = _FakeResumeRemote();
      final engine = SyncEngine(
        database: database,
        resumes: remote,
        dio: Dio(),
      );

      final result = await engine.run(source: SyncRunSource.foreground);

      expect(result.succeeded, isTrue);
      expect(remote.lastResumeId, isNull);
    },
  );
}

class _FakeResumeRemote extends ResumeRemoteDataSource {
  _FakeResumeRemote({this.failure}) : super(dio: Dio());

  final ResumeSaveFailureKind? failure;
  String? lastResumeId;

  @override
  Future<CreatedResumeModel> saveResume({
    String? resumeId,
    required String templateId,
    required String title,
    required Map<String, dynamic> data,
    required bool draft,
    int? baseRevision,
  }) async {
    lastResumeId = resumeId;
    if (failure != null) {
      throw ResumeSaveException(kind: failure!, message: 'fake failure');
    }
    return const CreatedResumeModel(
      id: 'remote-1',
      title: 'Local resume',
      revision: 4,
    );
  }
}
