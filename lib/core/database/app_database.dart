import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class CachedResources extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get payload => text()();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get staleAt => dateTime()();
  TextColumn get etag => text().nullable()();
  TextColumn get resourceVersion => text().nullable()();
  IntColumn get cacheSchema => integer()();

  @override
  Set<Column<Object>> get primaryKey => {cacheKey};
}

class LocalResumes extends Table {
  TextColumn get localId => text()();
  TextColumn get userId => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get payload => text()();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  BoolColumn get tombstone => boolean().withDefault(const Constant(false))();
  TextColumn get conflictOf => text().nullable()();
  TextColumn get failureKind => text().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class MutationOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityLocalId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  IntColumn get baseRevision => integer().nullable()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  BoolColumn get permanentFailure =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

class OptimizationSnapshots extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get userId => text()();
  TextColumn get sessionId => text()();
  TextColumn get payload => text()();
  BoolColumn get stale => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {cacheKey};
}

class SyncEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get source => text()();
  TextColumn get outcome => text()();
  IntColumn get processed => integer().withDefault(const Constant(0))();
  IntColumn get failed => integer().withDefault(const Constant(0))();
  TextColumn get details => text().nullable()();
}

@DriftDatabase(
  tables: [
    CachedResources,
    LocalResumes,
    MutationOutbox,
    OptimizationSnapshots,
    SyncEvents,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor})
    : super(executor ?? driftDatabase(name: 'prepmate_offline'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(localResumes);
        await migrator.createTable(mutationOutbox);
        await migrator.createTable(optimizationSnapshots);
        await migrator.createTable(syncEvents);
      }
    },
  );

  Future<CachedResource?> readResource(String key) {
    return (select(
      cachedResources,
    )..where((row) => row.cacheKey.equals(key))).getSingleOrNull();
  }

  Stream<CachedResource?> watchResource(String key) {
    return (select(
      cachedResources,
    )..where((row) => row.cacheKey.equals(key))).watchSingleOrNull();
  }

  Future<void> writeResource(CachedResourcesCompanion resource) {
    return into(cachedResources).insertOnConflictUpdate(resource);
  }

  Future<void> removeResource(String key) {
    return (delete(
      cachedResources,
    )..where((row) => row.cacheKey.equals(key))).go();
  }

  Future<void> removeResourcesWithPrefix(String prefix) {
    return (delete(
      cachedResources,
    )..where((row) => row.cacheKey.like('$prefix%'))).go();
  }

  Future<void> removeExpiredResources(DateTime now) {
    return (delete(
      cachedResources,
    )..where((row) => row.staleAt.isSmallerThanValue(now))).go();
  }

  Future<LocalResume?> readLocalResume(String localId) => (select(
    localResumes,
  )..where((row) => row.localId.equals(localId))).getSingleOrNull();

  Stream<List<LocalResume>> watchLocalResumes(String accountId) =>
      (select(localResumes)
            ..where((row) => row.userId.equals(accountId) & row.tombstone.not())
            ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
          .watch();

  Future<List<MutationOutboxData>> readyMutations(DateTime now) =>
      (select(mutationOutbox)
            ..where(
              (row) =>
                  row.permanentFailure.not() &
                  (row.nextAttemptAt.isNull() |
                      row.nextAttemptAt.isSmallerOrEqualValue(now)),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
          .get();

  Future<void> clearUserOfflineData(String accountId) async {
    await transaction(() async {
      await (delete(
        localResumes,
      )..where((row) => row.userId.equals(accountId))).go();
      await (delete(
        mutationOutbox,
      )..where((row) => row.userId.equals(accountId))).go();
      await (delete(
        optimizationSnapshots,
      )..where((row) => row.userId.equals(accountId))).go();
    });
  }
}
