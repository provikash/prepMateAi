import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cache/cache_store.dart';
import '../cache/pdf_cache_store.dart';
import 'form_provider.dart';
import '../../features/home/providers/home_providers.dart' as home;
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../features/resume/presentation/providers/resume_providers.dart';
import '../../features/resume/presentation/providers/resume_builder_provider.dart';
import '../../features/resume_analyzer/presentation/providers/resume_analyzer_providers.dart';
import '../../features/courses/presentation/providers/course_providers.dart';

/// Discard account-specific caches whenever the signed-in identity changes.
void clearSessionData(WidgetRef ref, {String? previousUserId}) {
  ref.invalidate(home.bottomNavProvider);
  ref.invalidate(home.dashboardProvider);
  ref.invalidate(home.resumeListProvider);
  ref.invalidate(profileProvider);
  ref.invalidate(storedResumesProvider);
  ref.invalidate(pdfViewerProvider);
  ref.invalidate(resumeBuilderProvider);
  ref.invalidate(resumeFormProvider);
  ref.invalidate(createResumeProvider);
  ref.invalidate(analyzeProvider);
  ref.invalidate(historyProvider);
  ref.invalidate(analysisDetailProvider);
  ref.invalidate(courseRecommendationsProvider);
  ref.invalidate(courseProgressProvider);
  ref.invalidate(allCourseProgressProvider);
  if (previousUserId != null && previousUserId.isNotEmpty) {
    unawaited(
      ref
          .read(cacheStoreProvider)
          .removeByPrefix(CacheKeyFactory.userPrefix(previousUserId)),
    );
    unawaited(ref.read(pdfCacheStoreProvider).removeForUser(previousUserId));
  }
}
