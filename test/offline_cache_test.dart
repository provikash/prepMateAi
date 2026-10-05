import 'package:flutter/material.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/core/cache/cache_store.dart';
import 'package:prepmate_mobile/core/database/app_database.dart';
import 'package:prepmate_mobile/core/network/request_deduplicator.dart';
import 'package:prepmate_mobile/core/offline/offline_status.dart';
import 'package:prepmate_mobile/core/widgets/offline_status_banner.dart';

void main() {
  late AppDatabase database;
  late DriftCacheStore store;
  late CacheCoordinator cache;

  setUp(() {
    database = AppDatabase(executor: NativeDatabase.memory());
    store = DriftCacheStore(database);
    cache = CacheCoordinator(store, RequestDeduplicator());
  });

  tearDown(() => database.close());

  test(
    'remote refresh is persisted and emitted through the local stream',
    () async {
      final result = await cache
          .watch<Map<String, dynamic>>(
            key: 'profile:user-1',
            userId: 'user-1',
            policy: CachePolicy.profile,
            decode: (value) => Map<String, dynamic>.from(value! as Map),
            encode: (value) => value,
            remote: () async => {'name': 'Alex'},
          )
          .first;

      expect(result.value, {'name': 'Alex'});
      expect(result.isOffline, isFalse);
      expect((await store.read('profile:user-1'))?.value, {'name': 'Alex'});
    },
  );

  test(
    'cached data remains readable and is marked offline when refresh fails',
    () async {
      final now = DateTime.now();
      await store.write(
        CacheEntry(
          key: 'resumes:user-1',
          value: const [
            {'id': 'resume-1', 'title': 'Saved resume'},
          ],
          userId: 'user-1',
          createdAt: now.subtract(const Duration(hours: 1)),
          expiresAt: now.subtract(const Duration(minutes: 30)),
          staleAt: now.add(const Duration(days: 1)),
        ),
      );

      final values = await cache
          .watch<List<dynamic>>(
            key: 'resumes:user-1',
            userId: 'user-1',
            policy: CachePolicy.resumeList,
            decode: (value) => List<dynamic>.from(value! as List),
            encode: (value) => value,
            remote: () => Future.error(Exception('offline')),
          )
          .take(2)
          .toList();

      expect(values.first.value.single['id'], 'resume-1');
      expect(values.first.isStale, isTrue);
      expect(values.last.isOffline, isTrue);
    },
  );

  test('account cache removal only removes the selected user prefix', () async {
    final now = DateTime.now();
    Future<void> put(String key) => store.write(
      CacheEntry(
        key: key,
        value: const {'saved': true},
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 1)),
        staleAt: now.add(const Duration(days: 1)),
      ),
    );

    await put('v3:user:user-1:profile');
    await put('v3:user:user-2:profile');
    await store.removeByPrefix('v3:user:user-1:');

    expect(await store.read('v3:user:user-1:profile'), isNull);
    expect(await store.read('v3:user:user-2:profile'), isNotNull);
  });

  testWidgets('offline status is visible with the saved-data timestamp', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineStatusBanner(
            status: OfflineStatus(
              isOffline: true,
              isStale: true,
              updatedAt: DateTime(2026, 1, 2, 10, 30),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Offline'), findsOneWidget);
    expect(find.textContaining('saved data from'), findsOneWidget);
  });
}
