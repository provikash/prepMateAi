import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../network/request_deduplicator.dart';
import '../network/request_interceptors.dart';

const int cacheSchemaVersion = 3;

class CachePolicy {
  const CachePolicy({required this.freshFor, required this.usableFor});

  final Duration freshFor;
  final Duration usableFor;

  static const templates = CachePolicy(
    freshFor: Duration(hours: 12),
    usableFor: Duration(days: 3),
  );
  static const templateDetail = CachePolicy(
    freshFor: Duration(hours: 24),
    usableFor: Duration(days: 7),
  );
  static const courseCategories = CachePolicy(
    freshFor: Duration(hours: 12),
    usableFor: Duration(days: 3),
  );
  static const courseResults = CachePolicy(
    freshFor: Duration(hours: 2),
    usableFor: Duration(hours: 12),
  );
  static const profile = CachePolicy(
    freshFor: Duration(minutes: 10),
    usableFor: Duration(days: 1),
  );
  static const resumeList = CachePolicy(
    freshFor: Duration(minutes: 2),
    usableFor: Duration(hours: 12),
  );
  static const resumeDetail = CachePolicy(
    freshFor: Duration(minutes: 2),
    usableFor: Duration(hours: 12),
  );
  static const atsHistory = CachePolicy(
    freshFor: Duration(minutes: 2),
    usableFor: Duration(hours: 12),
  );
}

class CacheEntry {
  const CacheEntry({
    required this.key,
    required this.value,
    required this.createdAt,
    required this.expiresAt,
    required this.staleAt,
    this.userId,
    this.etag,
    this.resourceVersion,
    this.schemaVersion = cacheSchemaVersion,
  });

  final String key;
  final Object? value;
  final String? userId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime staleAt;
  final String? etag;
  final String? resourceVersion;
  final int schemaVersion;

  bool isFresh(DateTime now) => now.isBefore(expiresAt);
  bool isUsable(DateTime now) => now.isBefore(staleAt);
}

abstract interface class CacheStore {
  Future<CacheEntry?> read(String key);
  Stream<CacheEntry?> watch(String key);
  Future<void> write(CacheEntry entry);
  Future<void> remove(String key);
  Future<void> removeByPrefix(String prefix);
  Future<void> clearExpired();
}

class DriftCacheStore implements CacheStore {
  DriftCacheStore(this.database);

  final AppDatabase database;

  CacheEntry? _decode(CachedResource? row) {
    if (row == null || row.cacheSchema != cacheSchemaVersion) return null;
    try {
      return CacheEntry(
        key: row.cacheKey,
        value: jsonDecode(row.payload),
        userId: row.userId,
        createdAt: row.createdAt,
        expiresAt: row.expiresAt,
        staleAt: row.staleAt,
        etag: row.etag,
        resourceVersion: row.resourceVersion,
        schemaVersion: row.cacheSchema,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CacheEntry?> read(String key) async {
    final row = await database.readResource(key);
    final entry = _decode(row);
    if (row != null && entry == null) await remove(key);
    return entry;
  }

  @override
  Stream<CacheEntry?> watch(String key) {
    return database
        .watchResource(key)
        .map(_decode)
        .distinct(
          (previous, next) =>
              previous?.createdAt == next?.createdAt &&
              previous?.value == next?.value,
        );
  }

  @override
  Future<void> write(CacheEntry entry) {
    return database.writeResource(
      CachedResourcesCompanion.insert(
        cacheKey: entry.key,
        payload: jsonEncode(entry.value),
        userId: Value(entry.userId),
        createdAt: entry.createdAt,
        expiresAt: entry.expiresAt,
        staleAt: entry.staleAt,
        etag: Value(entry.etag),
        resourceVersion: Value(entry.resourceVersion),
        cacheSchema: entry.schemaVersion,
      ),
    );
  }

  @override
  Future<void> remove(String key) => database.removeResource(key);

  @override
  Future<void> removeByPrefix(String prefix) =>
      database.removeResourcesWithPrefix(prefix);

  @override
  Future<void> clearExpired() =>
      database.removeExpiredResources(DateTime.now().toUtc());
}

class CachedValue<T> {
  const CachedValue({
    required this.value,
    required this.updatedAt,
    required this.isStale,
    this.isOffline = false,
  });

  final T value;
  final DateTime updatedAt;
  final bool isStale;
  final bool isOffline;

  CachedValue<T> copyWith({bool? isOffline}) => CachedValue(
    value: value,
    updatedAt: updatedAt,
    isStale: isStale,
    isOffline: isOffline ?? this.isOffline,
  );
}

class CacheKeyFactory {
  const CacheKeyFactory._();

  static String public(
    String resource, [
    Map<String, Object?> values = const {},
  ]) => 'v$cacheSchemaVersion:public:$resource:${_parameters(values)}';

  static String user(
    String userId,
    String resource, [
    Map<String, Object?> values = const {},
  ]) => 'v$cacheSchemaVersion:user:$userId:$resource:${_parameters(values)}';

  static String userPrefix(String userId) =>
      'v$cacheSchemaVersion:user:$userId:';

  static String _parameters(Map<String, Object?> values) {
    if (values.isEmpty) return 'default';
    final entries = values.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final canonical = entries
        .map((entry) => '${entry.key}=${entry.value ?? ''}')
        .join('&');
    return _fnv1a(canonical);
  }

  static String _fnv1a(String value) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

class CacheCoordinator {
  CacheCoordinator(this.store, this.deduplicator);

  final CacheStore store;
  final RequestDeduplicator deduplicator;

  Future<void> put<T>({
    required String key,
    required CachePolicy policy,
    required T value,
    required Object? Function(T value) encode,
    String? userId,
    String? resourceVersion,
  }) async {
    final now = DateTime.now();
    await store.write(
      CacheEntry(
        key: key,
        value: encode(value),
        userId: userId,
        createdAt: now,
        expiresAt: now.add(policy.freshFor),
        staleAt: now.add(policy.usableFor),
        resourceVersion: resourceVersion,
      ),
    );
  }

  Future<T> get<T>({
    required String key,
    required CachePolicy policy,
    required T Function(Object? value) decode,
    required Object? Function(T value) encode,
    required Future<T> Function() remote,
    String? userId,
    bool forceRefresh = false,
    void Function(T value)? onRevalidated,
  }) async {
    final now = DateTime.now();
    final cached = forceRefresh ? null : await store.read(key);
    if (cached != null && cached.isUsable(now)) {
      final value = decode(cached.value);
      if (cached.isFresh(now)) {
        NetworkMetrics.instance.cacheHits++;
        return value;
      }
      NetworkMetrics.instance.cacheStale++;
      unawaited(
        _fetchAndStore(
          key: key,
          policy: policy,
          encode: encode,
          remote: remote,
          userId: userId,
        ).then((fresh) => onRevalidated?.call(fresh)).catchError((_) {}),
      );
      return value;
    }

    NetworkMetrics.instance.cacheMisses++;
    return _fetchAndStore(
      key: key,
      policy: policy,
      encode: encode,
      remote: remote,
      userId: userId,
    );
  }

  Stream<CachedValue<T>> watch<T>({
    required String key,
    required CachePolicy policy,
    required T Function(Object? value) decode,
    required Object? Function(T value) encode,
    required Future<T> Function() remote,
    String? userId,
  }) async* {
    final initial = await store.read(key);
    final now = DateTime.now();
    var lastCreatedAt = initial?.createdAt;
    if (initial != null && initial.isUsable(now)) {
      yield CachedValue(
        value: decode(initial.value),
        updatedAt: initial.createdAt,
        isStale: !initial.isFresh(now),
      );
    }

    try {
      await _fetchAndStore(
        key: key,
        policy: policy,
        encode: encode,
        remote: remote,
        userId: userId,
      );
    } catch (_) {
      if (initial == null || !initial.isUsable(now)) rethrow;
      yield CachedValue(
        value: decode(initial.value),
        updatedAt: initial.createdAt,
        isStale: true,
        isOffline: true,
      );
    }

    await for (final entry in store.watch(key)) {
      if (entry == null) continue;
      if (entry.createdAt == lastCreatedAt) continue;
      lastCreatedAt = entry.createdAt;
      final observedAt = DateTime.now();
      if (!entry.isUsable(observedAt)) continue;
      yield CachedValue(
        value: decode(entry.value),
        updatedAt: entry.createdAt,
        isStale: !entry.isFresh(observedAt),
      );
    }
  }

  Future<T> refresh<T>({
    required String key,
    required CachePolicy policy,
    required Object? Function(T value) encode,
    required Future<T> Function() remote,
    String? userId,
  }) => _fetchAndStore(
    key: key,
    policy: policy,
    encode: encode,
    remote: remote,
    userId: userId,
  );

  Future<T> _fetchAndStore<T>({
    required String key,
    required CachePolicy policy,
    required Object? Function(T value) encode,
    required Future<T> Function() remote,
    String? userId,
  }) => deduplicator.run(key, () async {
    final value = await remote();
    final now = DateTime.now();
    await store.write(
      CacheEntry(
        key: key,
        value: encode(value),
        userId: userId,
        createdAt: now,
        expiresAt: now.add(policy.freshFor),
        staleAt: now.add(policy.usableFor),
      ),
    );
    return value;
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final cacheStoreProvider = Provider<CacheStore>((ref) {
  final store = DriftCacheStore(ref.watch(appDatabaseProvider));
  unawaited(store.clearExpired());
  return store;
});

final requestDeduplicatorProvider = Provider<RequestDeduplicator>((ref) {
  final value = RequestDeduplicator();
  ref.onDispose(value.clear);
  return value;
});

final cacheCoordinatorProvider = Provider<CacheCoordinator>((ref) {
  return CacheCoordinator(
    ref.watch(cacheStoreProvider),
    ref.watch(requestDeduplicatorProvider),
  );
});
