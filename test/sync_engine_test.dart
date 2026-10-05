import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull;
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

  Future<void> stage({String status = 'pending'}) async {
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
}

class _FakeResumeRemote extends ResumeRemoteDataSource {
  _FakeResumeRemote({this.failure}) : super(dio: Dio());

  final ResumeSaveFailureKind? failure;

  @override
  Future<CreatedResumeModel> saveResume({
    String? resumeId,
    required String templateId,
    required String title,
    required Map<String, dynamic> data,
    required bool draft,
    int? baseRevision,
  }) async {
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
