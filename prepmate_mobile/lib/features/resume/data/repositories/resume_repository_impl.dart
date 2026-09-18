import 'dart:typed_data';

import '../../domain/repositories/resume_repository.dart';
import '../datasources/resume_remote_data_source.dart';
import '../models/created_resume_model.dart';
import '../models/resume_model.dart';
import '../models/template_detail_model.dart';
import '../../../../core/cache/cache_store.dart';
import '../../../../core/cache/pdf_cache_store.dart';

class ResumeRepositoryImpl implements ResumeRepository {
  final ResumeRemoteDataSource remote;
  final CacheCoordinator cache;
  final PdfCacheStore pdfCache;
  final String? Function() userId;

  ResumeRepositoryImpl(
    this.remote, {
    required this.cache,
    required this.pdfCache,
    required this.userId,
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
    final created = await remote.createResume(
      templateId: templateId,
      title: title,
      data: data,
    );
    await _invalidateResumeCollections();
    return created;
  }

  @override
  Future<CreatedResumeModel> saveResume({
    String? resumeId,
    required String templateId,
    required String title,
    required Map<String, dynamic> data,
    required bool draft,
  }) async {
    final saved = await remote.saveResume(
      resumeId: resumeId,
      templateId: templateId,
      title: title,
      data: data,
      draft: draft,
    );
    await _invalidateResumeCollections();
    final id = userId();
    if (id != null) await pdfCache.remove(id, saved.id);
    return saved;
  }

  @override
  Future<String> getResumePdfUrl(String id) => remote.getResumePdfUrl(id);

  @override
  Future<Uint8List> getResumePdfBytes(String id) async {
    final accountId = userId();
    if (accountId == null) return remote.getResumePdfBytes(id);
    final metadata = await pdfCache.metadata(accountId, id);
    if (metadata != null && pdfCache.isFresh(metadata)) {
      final bytes = await pdfCache.read(metadata);
      if (bytes != null) return bytes;
    }
    return cache.deduplicator.run('pdf:$accountId:$id', () async {
      var result = await remote.fetchResumePdf(id, etag: metadata?.etag);
      if (result.notModified) {
        final bytes = metadata == null ? null : await pdfCache.read(metadata);
        if (bytes != null) return bytes;
        result = await remote.fetchResumePdf(id);
      }
      final bytes = result.bytes;
      if (bytes == null) throw Exception('Empty PDF response');
      await pdfCache.write(
        userId: accountId,
        resumeId: id,
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
    await remote.deleteResume(id);
    final accountId = userId();
    if (accountId != null) await pdfCache.remove(accountId, id);
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
