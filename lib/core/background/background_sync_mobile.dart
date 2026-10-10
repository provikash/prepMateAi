import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/resume/presentation/providers/resume_providers.dart';
import '../sync/sync_engine.dart';

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

Future<void> configureBackgroundSync() async {
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
}
