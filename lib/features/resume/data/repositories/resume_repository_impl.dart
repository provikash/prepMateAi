import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/repositories/resume_repository.dart';
import '../datasources/resume_remote_data_source.dart';
import '../models/created_resume_model.dart';
import '../models/resume_model.dart';
import '../models/template_detail_model.dart';
import '../../../../core/cache/cache_store.dart';
import '../../../../core/cache/pdf_cache_store.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_engine.dart';

class ResumeRepositoryImpl implements ResumeRepository {
  final ResumeRemoteDataSource remote;
  final CacheCoordinator cache;
  final PdfCacheStore pdfCache;
  final String? Function() userId;
  final AppDatabase database;
  final SyncEngine syncEngine;

  ResumeRepositoryImpl(
    this.remote, {
    required this.cache,
    required this.pdfCache,
    required this.userId,
    required this.database,
    required this.syncEngine,
  });

  @override
  Future<TemplateDetailModel> getTemplateDetail(String id) => cache.get(
    key: CacheKeyFactory.public('template', {'id': id}),
    policy: CachePolicy.templateDetail,
    decode: (value) =>
        TemplateDetailModel.fromJson(Map<String, dynamic>.from(value! as Map)),
    encode: (value) => value.toJson(),
    remote: () => remote.getTemplateDetail(id),
  );

  @override
  Future<CreatedResumeModel> createResume({
    required String templateId,
    required String title,
    required Map<String, dynamic> data,
  }) async {
    return saveResume(
      templateId: templateId,
      title: title,
      data: data,
      draft: false,
    );
  }

  @override
  Future<CreatedResumeModel> saveResume({
    String? resumeId,
    required String templateId,
    required String title,
    required Map<String, dynamic> data,
    required bool draft,
  }) async {
    final accountId = userId();
    if (accountId == null) {
      throw const ResumeSaveException(
        kind: ResumeSaveFailureKind.authentication,
        message: 'Sign in again before saving this resume.',
      );
    }
    final now = DateTime.now();
    final localId = resumeId ?? 'local-${now.microsecondsSinceEpoch}';
    final existing = await database.readLocalResume(localId);
    final payload = <String, dynamic>{
      'template_id': templateId,
      'title': title,
      'data': data,
      'draft': draft,
    };
    await database.transaction(() async {
      await database
          .into(database.localResumes)
          .insertOnConflictUpdate(
            LocalResumesCompanion.insert(
              localId: localId,
              userId: accountId,
              remoteId: Value(existing?.remoteId ?? resumeId),
              payload: jsonEncode(payload),
              revision: Value(existing?.revision ?? (resumeId == null ? 0 : 1)),
              syncStatus: const Value('pending'),
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
            ),
          );
      await (database.delete(database.mutationOutbox)..where(
            (row) =>
                row.entityType.equals('resume') &
                row.entityLocalId.equals(localId) &
                row.operation.equals('save') &
                row.permanentFailure.not(),
          ))
          .go();
      await database
          .into(database.mutationOutbox)
          .insert(
            MutationOutboxCompanion.insert(
              userId: accountId,
              entityType: 'resume',
              entityLocalId: localId,
              operation: 'save',
              payload: jsonEncode(payload),
              baseRevision: Value(
                existing?.revision ?? (resumeId == null ? null : 1),
              ),
              createdAt: now,
            ),
          );
    });
    final result = await syncEngine.run(source: SyncRunSource.foreground);
    final local = await database.readLocalResume(localId);
    await _invalidateResumeCollections();
    if (resumeId != null) await pdfCache.markStale(accountId, resumeId);
    return CreatedResumeModel(
      id: local?.remoteId ?? localId,
      title: title,
      revision: local?.revision ?? 0,
      queued: local?.syncStatus != 'synced' || !result.succeeded,
    );
  }

  @override
  Future<String> getResumePdfUrl(String id) => remote.getResumePdfUrl(id);

  @override
  Future<Uint8List> getResumePdfBytes(String id) async {
    final accountId = userId();
    if (accountId == null) return remote.getResumePdfBytes(id);
    final local = await database.readLocalResume(id);
    final remoteId = local?.remoteId ?? id;
    final metadata = await pdfCache.metadata(accountId, id);
    if (metadata != null && !metadata.stale && pdfCache.isFresh(metadata)) {
      final bytes = await pdfCache.read(metadata);
      if (bytes != null) return bytes;
    }
    return cache.deduplicator.run('pdf:$accountId:$remoteId', () async {
      var result = await remote.fetchResumePdf(remoteId, etag: metadata?.etag);
      if (result.notModified) {
        final bytes = metadata == null ? null : await pdfCache.read(metadata);
        if (bytes != null) return bytes;
        result = await remote.fetchResumePdf(remoteId);
      }
      final bytes = result.bytes;
      if (bytes == null) throw Exception('Empty PDF response');
      await pdfCache.write(
        userId: accountId,
        resumeId: remoteId,
        etag: result.etag ?? '',
        bytes: bytes,
      );
      return bytes;
    });
  }

  @override
  Future<Uint8List> downloadPdf(String id) => getResumePdfBytes(id);

  @override
  Future<void> deleteResume(String id) async {
    final accountId = userId();
    if (accountId == null) return remote.deleteResume(id);
    final now = DateTime.now();
    final existing = await database.readLocalResume(id);
    await database.transaction(() async {
      await database
          .into(database.localResumes)
          .insertOnConflictUpdate(
            LocalResumesCompanion.insert(
              localId: id,
              userId: accountId,
              remoteId: Value(existing?.remoteId ?? id),
              payload: existing?.payload ?? '{}',
              revision: Value(existing?.revision ?? 1),
              syncStatus: const Value('pending_delete'),
              tombstone: const Value(true),
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
            ),
          );
      await (database.delete(database.mutationOutbox)..where(
            (row) =>
                row.entityType.equals('resume') & row.entityLocalId.equals(id),
          ))
          .go();
      await database
          .into(database.mutationOutbox)
          .insert(
            MutationOutboxCompanion.insert(
              userId: accountId,
              entityType: 'resume',
              entityLocalId: id,
              operation: 'delete',
              payload: '{}',
              baseRevision: Value(existing?.revision ?? 1),
              createdAt: now,
            ),
          );
    });
    await pdfCache.remove(accountId, id);
    await syncEngine.run(source: SyncRunSource.foreground);
    await _invalidateResumeCollections();
  }

  @override
  Future<List<ResumeModel>> getResumes() {
    final id = userId();
    if (id == null) return remote.getResumes();
    return cache.get(
      key: CacheKeyFactory.user(id, 'builder_resumes', const {'page': 1}),
      userId: id,
      policy: CachePolicy.resumeList,
      decode: (value) => (value! as List)
          .map(
            (item) =>
                ResumeModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      encode: (value) => value.map((item) => item.toJson()).toList(),
      remote: remote.getResumes,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getTemplates() => cache.get(
    key: CacheKeyFactory.public('builder_templates', const {'page': 1}),
    policy: CachePolicy.templates,
    decode: (value) => (value! as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(),
    encode: (value) => value,
    remote: remote.getTemplates,
  );

  Future<void> _invalidateResumeCollections() async {
    final id = userId();
    if (id == null) return;
    await Future.wait([
      cache.store.remove(
        CacheKeyFactory.user(id, 'builder_resumes', const {'page': 1}),
      ),
      cache.store.remove(
        CacheKeyFactory.user(id, 'resumes', const {'page': 1}),
      ),
      cache.store.remove(CacheKeyFactory.user(id, 'dashboard')),
    ]);
  }
}
