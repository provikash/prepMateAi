import '../../../../core/cache/cache_store.dart';
import '../datasources/home_remote_data_source.dart';
import '../models/dashboard_model.dart';
import '../models/resume_model.dart';
import '../models/resume_detail_model.dart';
import '../models/template_model.dart';

class HomeRepository {
  HomeRepository({required this.remote, required this.cache});

  final HomeRemoteDataSource remote;
  final CacheCoordinator cache;

  String _resumeKey(String userId) =>
      CacheKeyFactory.user(userId, 'resumes', const {'page': 1});

  String get _templateKey =>
      CacheKeyFactory.public('templates', const {'page': 1});

  Future<DashboardModel> getDashboard({
    required String userId,
    bool forceRefresh = false,
    void Function(DashboardModel value)? onRevalidated,
  }) => cache.get(
    key: CacheKeyFactory.user(userId, 'dashboard'),
    userId: userId,
    policy: CachePolicy.resumeList,
    decode: (value) =>
        DashboardModel.fromJson(Map<String, dynamic>.from(value! as Map)),
    encode: (value) => value.toJson(),
    remote: remote.getDashboard,
    forceRefresh: forceRefresh,
    onRevalidated: onRevalidated,
  );

  Future<List<ResumeModel>> getResumes({
    required String userId,
    bool forceRefresh = false,
    void Function(List<ResumeModel> value)? onRevalidated,
  }) => cache.get(
    key: _resumeKey(userId),
    userId: userId,
    policy: CachePolicy.resumeList,
    decode: (value) => (value! as List)
        .map(
          (item) =>
              ResumeModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    encode: (value) => value.map((item) => item.toJson()).toList(),
    remote: remote.getResumes,
    forceRefresh: forceRefresh,
    onRevalidated: onRevalidated,
  );

  Stream<CachedValue<List<ResumeModel>>> watchResumes(String userId) =>
      cache.watch(
        key: _resumeKey(userId),
        userId: userId,
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

  Future<List<ResumeModel>> refreshResumes(String userId) => cache.refresh(
    key: _resumeKey(userId),
    userId: userId,
    policy: CachePolicy.resumeList,
    encode: (value) => value.map((item) => item.toJson()).toList(),
    remote: remote.getResumes,
  );

  Future<List<TemplateModel>> getTemplates({
    bool forceRefresh = false,
    void Function(List<TemplateModel> value)? onRevalidated,
  }) => cache.get(
    key: _templateKey,
    policy: CachePolicy.templates,
    decode: (value) => (value! as List)
        .map(
          (item) =>
              TemplateModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    encode: (value) => value.map((item) => item.toJson()).toList(),
    remote: remote.getTemplates,
    forceRefresh: forceRefresh,
    onRevalidated: onRevalidated,
  );

  Stream<CachedValue<List<TemplateModel>>> watchTemplates() => cache.watch(
    key: _templateKey,
    policy: CachePolicy.templates,
    decode: (value) => (value! as List)
        .map(
          (item) =>
              TemplateModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    encode: (value) => value.map((item) => item.toJson()).toList(),
    remote: remote.getTemplates,
  );

  Future<List<TemplateModel>> refreshTemplates() => cache.refresh(
    key: _templateKey,
    policy: CachePolicy.templates,
    encode: (value) => value.map((item) => item.toJson()).toList(),
    remote: remote.getTemplates,
  );

  Future<void> invalidateResumeData(String userId) async {
    await cache.store.remove(CacheKeyFactory.user(userId, 'dashboard'));
    await cache.store.remove(_resumeKey(userId));
  }

  Future<void> invalidateDashboard(String userId) =>
      cache.store.remove(CacheKeyFactory.user(userId, 'dashboard'));

  Future<void> deleteResume(String userId, String resumeId) async {
    await remote.deleteResume(resumeId);
    await invalidateResumeData(userId);
    await refreshResumes(userId);
  }

  Future<ResumeDetailModel> duplicateResume(
    String userId,
    String resumeId,
  ) async {
    final copy = await remote.duplicateResume(resumeId);
    await invalidateResumeData(userId);
    await refreshResumes(userId);
    return copy;
  }
}
