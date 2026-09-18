import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_router.dart';
import 'config/api_config.dart';

import 'config/theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/session_cleanup.dart';
import 'features/auth/presentation/viewmodel/auth_viewmodel.dart';

void main() {
  if (kIsWeb) {
    throw UnsupportedError('PrepMate supports mobile platforms only.');
  }
  final endpoint = Uri.tryParse(apiBaseUrl);
  if (kReleaseMode &&
      (endpoint == null ||
          endpoint.scheme != 'https' ||
          endpoint.host.isEmpty)) {
    throw StateError(
      'A release build requires --dart-define=API_BASE_URL=https://your-host/api/v1/',
    );
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authViewModelProvider.select((state) => state.user?.id), (
      previous,
      next,
    ) {
      if (previous != next) {
        clearSessionData(ref, previousUserId: previous);
      }
    });
    final appRouter = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'PrepMate',
      routerConfig: appRouter,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: AppMotion.standard,
      themeAnimationCurve: Curves.easeOutCubic,
    );
  }
}
