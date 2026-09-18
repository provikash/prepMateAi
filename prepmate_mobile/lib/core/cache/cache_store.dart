import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
    'user_id': userId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'stale_at': staleAt.toUtc().toIso8601String(),
    'etag': etag,
    'resource_version': resourceVersion,
    'schema_version': schemaVersion,
  };

  static CacheEntry? tryParse(String encoded) {
    try {
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic> ||
          json['schema_version'] != cacheSchemaVersion) {
        return null;
      }
      return CacheEntry(
        key: json['key'] as String,
        value: json['value'],
        userId: json['user_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        expiresAt: DateTime.parse(json['expires_at'] as String),
        staleAt: DateTime.parse(json['stale_at'] as String),
        etag: json['etag'] as String?,
        resourceVersion: json['resource_version'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

abstract interface class CacheStore {
  Future<CacheEntry?> read(String key);
  Future<void> write(CacheEntry entry);
  Future<void> remove(String key);
  Future<void> removeByPrefix(String prefix);
  Future<void> clearExpired();
}

class SharedPreferencesCacheStore implements CacheStore {
  SharedPreferencesCacheStore({this.maximumEntries = 180});

  static const _prefix = 'prepmate_cache_';
  final int maximumEntries;
  Future<SharedPreferences>? _preferences;

  Future<SharedPreferences> get _prefs =>
      _preferences ??= SharedPreferences.getInstance();

  String _storageKey(String key) => '$_prefix$key';

  @override
  Future<CacheEntry?> read(String key) async {
    final prefs = await _prefs;
    final storageKey = _storageKey(key);
    final encoded = prefs.getString(storageKey);
    if (encoded == null) return null;
    final entry = CacheEntry.tryParse(encoded);
    if (entry == null || entry.key != key) {
      await prefs.remove(storageKey);
      return null;
    }
    return entry;
  }

  @override
  Future<void> write(CacheEntry entry) async {
    final prefs = await _prefs;
    await prefs.setString(_storageKey(entry.key), jsonEncode(entry.toJson()));
    await _evictIfNeeded(prefs);
  }

  @override
  Future<void> remove(String key) async {
    await (await _prefs).remove(_storageKey(key));
  }

  @override
  Future<void> removeByPrefix(String prefix) async {
    final prefs = await _prefs;
    final storagePrefix = _storageKey(prefix);
    final keys = prefs.getKeys().where((key) => key.startsWith(storagePrefix));
    await Future.wait(keys.map(prefs.remove));
  }

  @override
  Future<void> clearExpired() async {
    final prefs = await _prefs;
    final now = DateTime.now();
    for (final key in prefs.getKeys().where((key) => key.startsWith(_prefix))) {
      final encoded = prefs.getString(key);
      final entry = encoded == null ? null : CacheEntry.tryParse(encoded);
      if (entry == null || !entry.isUsable(now)) await prefs.remove(key);
    }
  }

  Future<void> _evictIfNeeded(SharedPreferences prefs) async {
    final entries = <MapEntry<String, CacheEntry>>[];
    for (final key in prefs.getKeys().where((key) => key.startsWith(_prefix))) {
      final encoded = prefs.getString(key);
      final entry = encoded == null ? null : CacheEntry.tryParse(encoded);
      if (entry == null) {
        await prefs.remove(key);
      } else {
        entries.add(MapEntry(key, entry));
      }
    }
    if (entries.length <= maximumEntries) return;
    entries.sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));
    for (final entry in entries.take(entries.length - maximumEntries)) {
      await prefs.remove(entry.key);
    }
  }
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

final cacheStoreProvider = Provider<CacheStore>((ref) {
  final store = SharedPreferencesCacheStore();
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
