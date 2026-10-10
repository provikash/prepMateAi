import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/repositories/resume_repository.dart';
import '../datasources/resume_remote_data_source.dart';
import '../models/created_resume_model.dart';
import '../models/resume_model.dart';
import '../models/template_detail_model.dart';
import '../services/local_resume_pdf_generator.dart';
import '../resume_id.dart';
import '../built_in_templates.dart';
import '../../../../core/cache/cache_store.dart';
import '../../../../core/cache/pdf_cache_store.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_engine.dart';

class ResumeRepositoryImpl implements ResumeRepository {
  final ResumeRemoteDataSource remote;
  final CacheCoordinator cache;
  final PdfCacheStore pdfCache;
  final String? Function() userId;
  final Future<LocalWorkspace> Function() workspace;
  final AppDatabase database;
  final SyncEngine syncEngine;

  ResumeRepositoryImpl(
    this.remote, {
    required this.cache,
    required this.pdfCache,
    required this.userId,
    required this.workspace,
    required this.database,
    required this.syncEngine,
  });

  @override
  Future<TemplateDetailModel> getTemplateDetail(String id) async {
    final bundled = builtInTemplateDetail(id);
    if (bundled != null) return bundled;
    try {
      return await cache.get(
        key: CacheKeyFactory.public('template_rendered_v2', {'id': id}),
        policy: CachePolicy.templateDetail,
        decode: (value) => TemplateDetailModel.fromJson(
          Map<String, dynamic>.from(value! as Map),
        ),
        encode: (value) => value.toJson(),
        remote: () => remote.getTemplateDetail(id),
      );
    } catch (_) {
      throw Exception(
        'This template has not been downloaded yet. Connect once or choose a built-in template.',
      );
    }
  }

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
    final activeWorkspace = await workspace();
    final now = DateTime.now();
    final existing = resumeId == null
        ? null
        : await database.readLocalResumeByAnyId(resumeId);
    final localId = existing?.localId ?? 'local-${now.microsecondsSinceEpoch}';
    final remoteId =
        serverResumeIdOrNull(existing?.remoteId) ??
        serverResumeIdOrNull(resumeId);
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
              workspaceId: Value(activeWorkspace.workspaceId),
              userId: activeWorkspace.workspaceId,
              remoteId: Value(remoteId),
              payload: jsonEncode(payload),
              revision: Value(existing?.revision ?? (remoteId == null ? 0 : 1)),
              syncStatus: Value(accountId == null ? 'local_only' : 'pending'),
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
      if (accountId != null) {
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
                  existing?.revision ?? (remoteId == null ? null : 1),
                ),
                createdAt: now,
              ),
            );
      }
    });
    final result = accountId == null
        ? const SyncRunResult(processed: 0, failed: 0, retryScheduled: false)
        : await syncEngine.run(source: SyncRunSource.foreground);
    final local = await database.readLocalResume(localId);
    await _invalidateResumeCollections();
    try {
      await pdfCache.markStale(
        accountId ?? activeWorkspace.workspaceId,
        localId,
      );
    } catch (_) {
      // PDF caching is optional and must never prevent saving.
    }
    if (accountId != null && remoteId != null) {
      await pdfCache.markStale(accountId, remoteId);
    }
    return CreatedResumeModel(
      id: serverResumeIdOrNull(local?.remoteId) ?? localId,
      title: title,
      revision: local?.revision ?? 0,
      queued:
          accountId == null ||
          local?.syncStatus != 'synced' ||
          !result.succeeded,
    );
  }

  @override
  Future<String> getResumePdfUrl(String id) => remote.getResumePdfUrl(id);

  @override
  Future<Uint8List> getResumePdfBytes(String id) async {
    final accountId = userId();
    var local = await database.readLocalResumeByAnyId(id);
    if (local != null) {
      final activeWorkspace = await workspace();
      final owner = accountId ?? activeWorkspace.workspaceId;
      final fingerprint = 'local-${local.updatedAt.microsecondsSinceEpoch}';
      final metadata = await pdfCache.metadata(owner, local.localId);
      if (metadata != null && !metadata.stale && metadata.etag == fingerprint) {
        final cached = await pdfCache.read(metadata);
        if (cached != null) return cached;
      }
      final payload = Map<String, dynamic>.from(
        jsonDecode(local.payload) as Map,
      );
      final data = Map<String, dynamic>.from(
        payload['data'] as Map? ?? const {},
      );
      final bytes = await const LocalResumePdfGenerator().generate(
        data: data,
        templateId: payload['template_id']?.toString() ?? '',
      );
      if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
        throw Exception('Could not build a valid PDF preview.');
      }
      try {
        await pdfCache.write(
          userId: owner,
          resumeId: local.localId,
          etag: fingerprint,
          bytes: bytes,
        );
      } catch (_) {
        // The generated PDF remains usable when persistent caching is full.
      }
      return bytes;
    }
    if (accountId == null) {
      throw Exception('This resume is not available on this device.');
    }
    var remoteId =
        serverResumeIdOrNull(local?.remoteId) ?? serverResumeIdOrNull(id);
    if (remoteId == null && local != null) {
      await syncEngine.run(source: SyncRunSource.foreground);
      local = await database.readLocalResume(id);
      remoteId = serverResumeIdOrNull(local?.remoteId);
    }
    if (remoteId == null) {
      throw Exception(
        'This resume is still syncing. Connect to the internet and try again.',
      );
    }
    final resolvedRemoteId = remoteId;
    final metadata = await pdfCache.metadata(accountId, resolvedRemoteId);
    if (metadata != null && !metadata.stale && pdfCache.isFresh(metadata)) {
      final bytes = await pdfCache.read(metadata);
      if (bytes != null) return bytes;
    }
    return cache.deduplicator.run('pdf:$accountId:$resolvedRemoteId', () async {
      var result = await remote.fetchResumePdf(
        resolvedRemoteId,
        etag: metadata?.etag,
      );
      if (result.notModified) {
        final bytes = metadata == null ? null : await pdfCache.read(metadata);
        if (bytes != null) return bytes;
        result = await remote.fetchResumePdf(resolvedRemoteId);
      }
      final bytes = result.bytes;
      if (bytes == null) throw Exception('Empty PDF response');
      if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
        throw Exception(
          'The server did not return a valid PDF. Please try again.',
        );
      }
      // The preview should remain usable even if local caching fails.
      try {
        await pdfCache.write(
          userId: accountId,
          resumeId: resolvedRemoteId,
          etag: result.etag ?? '',
          bytes: bytes,
        );
      } catch (_) {
        // Caching is an optimization; the downloaded PDF is still valid.
      }
      return bytes;
    });
  }

  @override
  Future<Uint8List> downloadPdf(String id) => getResumePdfBytes(id);

  @override
  Future<void> renameResume(String id, String title) async {
    final existing = await database.readLocalResumeByAnyId(id);
    if (existing == null) {
      throw StateError('Download this resume before editing it offline.');
    }
    final payload = Map<String, dynamic>.from(
      jsonDecode(existing.payload) as Map,
    );
    await saveResume(
      resumeId: existing.localId,
      templateId: payload['template_id']?.toString() ?? '',
      title: title,
      data: Map<String, dynamic>.from(payload['data'] as Map? ?? const {}),
      draft: payload['draft'] == true,
    );
  }

  @override
  Future<CreatedResumeModel> duplicateResume(String id) async {
    final existing = await database.readLocalResumeByAnyId(id);
    if (existing == null) {
      throw StateError('Download this resume before duplicating it offline.');
    }
    final payload = Map<String, dynamic>.from(
      jsonDecode(existing.payload) as Map,
    );
    return saveResume(
      templateId: payload['template_id']?.toString() ?? '',
      title: '${payload['title'] ?? 'Resume'} copy',
      data: Map<String, dynamic>.from(payload['data'] as Map? ?? const {}),
      draft: payload['draft'] == true,
    );
  }

  @override
  Future<void> deleteResume(String id) async {
    final accountId = userId();
    final activeWorkspace = await workspace();
    final now = DateTime.now();
    final existing = await database.readLocalResumeByAnyId(id);
    if (accountId == null) {
      if (existing != null) {
        await database.transaction(() async {
          await (database.delete(
            database.mutationOutbox,
          )..where((row) => row.entityLocalId.equals(existing.localId))).go();
          await (database.delete(
            database.localResumes,
          )..where((row) => row.localId.equals(existing.localId))).go();
        });
      }
      return;
    }
    final remoteId =
        serverResumeIdOrNull(existing?.remoteId) ?? serverResumeIdOrNull(id);
    await database.transaction(() async {
      await database
          .into(database.localResumes)
          .insertOnConflictUpdate(
            LocalResumesCompanion.insert(
              localId: existing?.localId ?? id,
              workspaceId: Value(activeWorkspace.workspaceId),
              userId: activeWorkspace.workspaceId,
              remoteId: Value(remoteId),
              payload: existing?.payload ?? '{}',
              revision: Value(existing?.revision ?? (remoteId == null ? 0 : 1)),
              syncStatus: const Value('pending_delete'),
              tombstone: const Value(true),
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
            ),
          );
      await (database.delete(database.mutationOutbox)..where(
            (row) =>
                row.entityType.equals('resume') &
                row.entityLocalId.equals(existing?.localId ?? id),
          ))
          .go();
      await database
          .into(database.mutationOutbox)
          .insert(
            MutationOutboxCompanion.insert(
              userId: accountId,
              entityType: 'resume',
              entityLocalId: existing?.localId ?? id,
              operation: 'delete',
              payload: '{}',
              baseRevision: Value(
                remoteId == null ? null : (existing?.revision ?? 1),
              ),
              createdAt: now,
            ),
          );
    });
    await pdfCache.remove(accountId, id);
    await syncEngine.run(source: SyncRunSource.foreground);
    await _invalidateResumeCollections();
  }

  @override
  Future<List<ResumeModel>> getResumes() async {
    final id = userId();
    if (id == null) {
      final activeWorkspace = await workspace();
      final local = await database
          .watchLocalResumes(activeWorkspace.workspaceId)
          .first;
      return local
          .map((row) {
            final payload = Map<String, dynamic>.from(
              jsonDecode(row.payload) as Map,
            );
            return ResumeModel(
              id: row.remoteId ?? row.localId,
              title: payload['title']?.toString() ?? 'Untitled Resume',
              pdfUrl: null,
            );
          })
          .toList(growable: false);
    }
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
    key: CacheKeyFactory.public('builder_templates_rendered_v2', const {
      'page': 1,
    }),
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
