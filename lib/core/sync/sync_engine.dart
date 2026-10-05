import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../features/resume/data/datasources/resume_remote_data_source.dart';
import '../database/app_database.dart';

enum SyncRunSource { manual, foreground, background }

class SyncRunResult {
  const SyncRunResult({
    required this.processed,
    required this.failed,
    required this.retryScheduled,
  });

  final int processed;
  final int failed;
  final bool retryScheduled;

  bool get succeeded => failed == 0;
}

class SyncEngine {
  SyncEngine({
    required AppDatabase database,
    required ResumeRemoteDataSource resumes,
    required Dio dio,
  }) : _database = database,
       _resumes = resumes,
       _dio = dio;

  final AppDatabase _database;
  final ResumeRemoteDataSource _resumes;
  final Dio _dio;
  Future<SyncRunResult>? _activeRun;

  Future<SyncRunResult> run({required SyncRunSource source}) {
    return _activeRun ??= _run(source).whenComplete(() => _activeRun = null);
  }

  Future<SyncRunResult> _run(SyncRunSource source) async {
    var processed = 0;
    var failed = 0;
    var retryScheduled = false;
    final items = await _database.readyMutations(DateTime.now());
    for (final item in items) {
      try {
        if (item.entityType == 'resume') {
          await _syncResume(item);
        } else if (item.entityType == 'suggestion_decision') {
          await _syncSuggestionDecision(item);
        } else {
          throw const _PermanentSyncException('Unsupported outbox operation.');
        }
        await (_database.delete(
          _database.mutationOutbox,
        )..where((row) => row.id.equals(item.id))).go();
        processed++;
      } on ResumeSaveException catch (error) {
        failed++;
        if (error.kind == ResumeSaveFailureKind.conflict) {
          await _createConflictCopy(item);
          await _markPermanent(item, error.message, kind: 'conflict');
        } else if (_isRetryableResumeError(error)) {
          retryScheduled = true;
          await _scheduleRetry(item, error.message);
        } else {
          await _markPermanent(item, error.message, kind: 'permanent');
        }
      } on DioException catch (error) {
        failed++;
        final status = error.response?.statusCode;
        if (status == null || status == 408 || status == 429 || status >= 500) {
          retryScheduled = true;
          await _scheduleRetry(item, error.message ?? 'Network failure');
        } else {
          await _markPermanent(
            item,
            error.response?.data?.toString() ?? error.message ?? 'Sync failed',
            kind: 'http_$status',
          );
        }
      } on _PermanentSyncException catch (error) {
        failed++;
        await _markPermanent(item, error.message, kind: 'permanent');
      } catch (error) {
        failed++;
        retryScheduled = true;
        await _scheduleRetry(item, error.toString());
      }
    }
    await _database
        .into(_database.syncEvents)
        .insert(
          SyncEventsCompanion.insert(
            occurredAt: DateTime.now(),
            source: source.name,
            outcome: failed == 0 ? 'success' : 'partial',
            processed: Value(processed),
            failed: Value(failed),
            details: Value(retryScheduled ? 'retry_scheduled' : null),
          ),
        );
    return SyncRunResult(
      processed: processed,
      failed: failed,
      retryScheduled: retryScheduled,
    );
  }

  Future<void> _syncResume(MutationOutboxData mutation) async {
    final local = await _database.readLocalResume(mutation.entityLocalId);
    if (local == null) return;
    if (mutation.operation == 'delete') {
      if (local.remoteId != null) {
        await _resumes.deleteResume(
          local.remoteId!,
          baseRevision: mutation.baseRevision,
        );
      }
      await (_database.delete(
        _database.localResumes,
      )..where((row) => row.localId.equals(local.localId))).go();
      return;
    }
    final payload = Map<String, dynamic>.from(
      jsonDecode(mutation.payload) as Map,
    );
    final saved = await _resumes.saveResume(
      resumeId: local.remoteId,
      templateId: payload['template_id'].toString(),
      title: payload['title']?.toString() ?? 'Resume',
      data: Map<String, dynamic>.from(payload['data'] as Map),
      draft: payload['draft'] == true,
      baseRevision: local.remoteId == null ? null : mutation.baseRevision,
    );
    await (_database.update(
      _database.localResumes,
    )..where((row) => row.localId.equals(local.localId))).write(
      LocalResumesCompanion(
        remoteId: Value(saved.id),
        revision: Value(saved.revision),
        syncStatus: const Value('synced'),
        failureKind: const Value(null),
        lastError: const Value(null),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _syncSuggestionDecision(MutationOutboxData mutation) async {
    final payload = Map<String, dynamic>.from(
      jsonDecode(mutation.payload) as Map,
    );
    await _dio.post(
      payload['path'].toString(),
      data: Map<String, dynamic>.from(payload['data'] as Map? ?? const {}),
    );
  }

  bool _isRetryableResumeError(ResumeSaveException error) =>
      error.kind == ResumeSaveFailureKind.connection ||
      error.kind == ResumeSaveFailureKind.timeout ||
      error.kind == ResumeSaveFailureKind.server ||
      error.kind == ResumeSaveFailureKind.authentication;

  Future<void> _scheduleRetry(MutationOutboxData item, String message) async {
    final attempts = item.attemptCount + 1;
    final minutes = min(360, pow(2, attempts.clamp(0, 8)).toInt());
    await (_database.update(
      _database.mutationOutbox,
    )..where((row) => row.id.equals(item.id))).write(
      MutationOutboxCompanion(
        attemptCount: Value(attempts),
        nextAttemptAt: Value(DateTime.now().add(Duration(minutes: minutes))),
        lastError: Value(message),
      ),
    );
    await _setResumeFailure(item, 'retryable', message, 'retrying');
  }

  Future<void> _markPermanent(
    MutationOutboxData item,
    String message, {
    required String kind,
  }) async {
    await (_database.update(
      _database.mutationOutbox,
    )..where((row) => row.id.equals(item.id))).write(
      MutationOutboxCompanion(
        permanentFailure: const Value(true),
        lastError: Value(message),
      ),
    );
    await _setResumeFailure(item, kind, message, kind);
  }

  Future<void> _setResumeFailure(
    MutationOutboxData item,
    String kind,
    String message,
    String status,
  ) async {
    if (item.entityType != 'resume') return;
    await (_database.update(
      _database.localResumes,
    )..where((row) => row.localId.equals(item.entityLocalId))).write(
      LocalResumesCompanion(
        syncStatus: Value(status),
        failureKind: Value(kind),
        lastError: Value(message),
      ),
    );
  }

  Future<void> _createConflictCopy(MutationOutboxData item) async {
    final local = await _database.readLocalResume(item.entityLocalId);
    if (local == null) return;
    final now = DateTime.now();
    final copyId = 'conflict-${now.microsecondsSinceEpoch}';
    final payload = Map<String, dynamic>.from(jsonDecode(local.payload) as Map);
    payload['title'] = '${payload['title'] ?? 'Resume'} (conflict copy)';
    await _database
        .into(_database.localResumes)
        .insert(
          LocalResumesCompanion.insert(
            localId: copyId,
            userId: local.userId,
            payload: jsonEncode(payload),
            syncStatus: const Value('conflict'),
            conflictOf: Value(local.remoteId ?? local.localId),
            failureKind: const Value('conflict'),
            lastError: const Value('Review this copy before syncing it.'),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }
}

class _PermanentSyncException implements Exception {
  const _PermanentSyncException(this.message);
  final String message;
}
