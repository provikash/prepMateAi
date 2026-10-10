import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prepmate_mobile/config/app_router.dart';
import 'package:prepmate_mobile/config/api_config.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/core/background/background_sync.dart';
import 'package:prepmate_mobile/core/offline/local_workspace.dart';
import 'package:prepmate_mobile/core/providers/theme_provider.dart';
import 'package:prepmate_mobile/core/providers/session_cleanup.dart';
import 'package:prepmate_mobile/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:prepmate_mobile/features/auth/presentation/state/auth_state.dart';
import 'package:prepmate_mobile/features/resume/presentation/providers/resume_providers.dart';
import 'package:prepmate_mobile/core/sync/sync_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final endpoint = Uri.tryParse(apiBaseUrl);
  if (kReleaseMode &&
      isProduction &&
      (endpoint == null ||
          endpoint.scheme != 'https' ||
          endpoint.host.isEmpty)) {
    throw StateError(
      'A production release requires '
      '--dart-define=API_BASE_URL=https://your-host/api/v1/',
    );
  }
  await configureBackgroundSync();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(authViewModelProvider).status == AuthStatus.authenticated) {
      ref
          .read(syncControllerProvider.notifier)
          .sync(source: SyncRunSource.foreground)
          .ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authViewModelProvider.select((state) => state.user?.id), (
      previous,
      next,
    ) {
      if (previous != next) {
        if (previous != null) {
          clearSessionData(ref, previousUserId: previous);
        }
        ref.invalidate(localWorkspaceProvider);
        if (next != null) {
          ref
              .read(localWorkspaceProvider.future)
              .then(
                (_) => ref
                    .read(syncControllerProvider.notifier)
                    .sync(source: SyncRunSource.foreground),
              )
              .ignore();
        }
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
