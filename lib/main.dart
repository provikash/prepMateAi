import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'config/app_router.dart';
import 'config/api_config.dart';

import 'config/theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/session_cleanup.dart';
import 'features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'features/auth/presentation/state/auth_state.dart';
import 'features/resume/presentation/providers/resume_providers.dart';
import 'core/sync/sync_engine.dart';

const _backgroundSyncTask = 'prepmate.offline.sync';

@pragma('vm:entry-point')
void backgroundSyncDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    final container = ProviderContainer();
    try {
      final result = await container
          .read(syncEngineProvider)
          .run(source: SyncRunSource.background);
      return !result.retryScheduled;
    } finally {
      container.dispose();
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  await Workmanager().initialize(backgroundSyncDispatcher);
  await Workmanager().registerPeriodicTask(
    _backgroundSyncTask,
    _backgroundSyncTask,
    frequency: const Duration(minutes: 30),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
      requiresStorageNotLow: true,
    ),
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 10),
  );
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
