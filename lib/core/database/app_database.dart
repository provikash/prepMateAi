import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class LocalWorkspaces extends Table {
  TextColumn get workspaceId => text()();
  TextColumn get accountId => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {workspaceId};
}

class LocalResumes extends Table {
  TextColumn get localId => text()();
  TextColumn get workspaceId => text().nullable()();
  // Retained for schema compatibility. New code stores the workspace id here.
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
    LocalWorkspaces,
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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(localWorkspaces);
        await migrator.createTable(localResumes);
        await migrator.createTable(mutationOutbox);
        await migrator.createTable(optimizationSnapshots);
        await migrator.createTable(syncEvents);
      } else if (from < 3) {
        await migrator.createTable(localWorkspaces);
        await migrator.addColumn(localResumes, localResumes.workspaceId);
        await customStatement('''
          INSERT OR IGNORE INTO local_workspaces
            (workspace_id, account_id, is_active, created_at, updated_at)
          SELECT user_id, user_id, 0, MIN(created_at), MAX(updated_at)
          FROM local_resumes
          GROUP BY user_id
        ''');
        await customStatement('''
          UPDATE local_resumes SET workspace_id = user_id
          WHERE workspace_id IS NULL
        ''');
      }
    },
  );

  String _newWorkspaceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String part(int start, int end) => bytes
        .sublist(start, end)
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${part(0, 4)}-${part(4, 6)}-${part(6, 8)}-'
        '${part(8, 10)}-${part(10, 16)}';
  }

  Future<LocalWorkspace> activateWorkspace({String? accountId}) =>
      transaction(() async {
        final now = DateTime.now();
        final active = await (select(
          localWorkspaces,
        )..where((row) => row.isActive.equals(true))).getSingleOrNull();

        LocalWorkspace? target;
        if (accountId != null) {
          target = await (select(
            localWorkspaces,
          )..where((row) => row.accountId.equals(accountId))).getSingleOrNull();
          if (target != null &&
              active != null &&
              active.accountId == null &&
              active.workspaceId != target.workspaceId) {
            await (update(localResumes)..where(
                  (row) =>
                      row.workspaceId.equals(active.workspaceId) |
                      (row.workspaceId.isNull() &
                          row.userId.equals(active.workspaceId)),
                ))
                .write(
                  LocalResumesCompanion(
                    workspaceId: Value(target.workspaceId),
                    userId: Value(target.workspaceId),
                  ),
                );
            await (delete(
              localWorkspaces,
            )..where((row) => row.workspaceId.equals(active.workspaceId))).go();
          }
          if (target == null && active?.accountId == null) {
            await (update(localWorkspaces)
                  ..where((row) => row.workspaceId.equals(active!.workspaceId)))
                .write(
                  LocalWorkspacesCompanion(
                    accountId: Value(accountId),
                    updatedAt: Value(now),
                  ),
                );
            target =
                await (select(localWorkspaces)..where(
                      (row) => row.workspaceId.equals(active!.workspaceId),
                    ))
                    .getSingle();
          }
        } else if (active?.accountId == null) {
          target = active;
        }

        target ??= accountId == null
            ? await (select(localWorkspaces)
                    ..where((row) => row.accountId.isNull())
                    ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
                  .getSingleOrNull()
            : null;

        if (target == null) {
          final id = _newWorkspaceId();
          await into(localWorkspaces).insert(
            LocalWorkspacesCompanion.insert(
              workspaceId: id,
              accountId: Value(accountId),
              isActive: const Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );
          target = await (select(
            localWorkspaces,
          )..where((row) => row.workspaceId.equals(id))).getSingle();
        }

        await update(
          localWorkspaces,
        ).write(const LocalWorkspacesCompanion(isActive: Value(false)));
        await (update(
          localWorkspaces,
        )..where((row) => row.workspaceId.equals(target!.workspaceId))).write(
          LocalWorkspacesCompanion(
            isActive: const Value(true),
            updatedAt: Value(now),
          ),
        );
        return (select(localWorkspaces)
              ..where((row) => row.workspaceId.equals(target!.workspaceId)))
            .getSingle();
      });

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

  Future<LocalResume?> readLocalResumeByAnyId(String id) =>
      (select(localResumes)
            ..where((row) => row.localId.equals(id) | row.remoteId.equals(id)))
          .getSingleOrNull();

  Stream<List<LocalResume>> watchLocalResumes(String workspaceId) =>
      (select(localResumes)
            ..where(
              (row) =>
                  (row.workspaceId.equals(workspaceId) |
                      (row.workspaceId.isNull() &
                          row.userId.equals(workspaceId))) &
                  row.tombstone.not(),
            )
            ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
          .watch();

  Future<void> queueWorkspaceResumesForSync({
    required String workspaceId,
    required String accountId,
  }) async {
    final rows =
        await (select(localResumes)..where(
              (row) =>
                  (row.workspaceId.equals(workspaceId) |
                      (row.workspaceId.isNull() &
                          row.userId.equals(workspaceId))) &
                  row.tombstone.not() &
                  row.syncStatus.equals('local_only'),
            ))
            .get();
    if (rows.isEmpty) return;
    await transaction(() async {
      for (final resume in rows) {
        final existing =
            await (select(mutationOutbox)..where(
                  (row) =>
                      row.entityType.equals('resume') &
                      row.entityLocalId.equals(resume.localId) &
                      row.operation.equals('save') &
                      row.permanentFailure.not(),
                ))
                .getSingleOrNull();
        if (existing == null) {
          await into(mutationOutbox).insert(
            MutationOutboxCompanion.insert(
              userId: accountId,
              entityType: 'resume',
              entityLocalId: resume.localId,
              operation: 'save',
              payload: resume.payload,
              baseRevision: Value(
                resume.remoteId == null ? null : resume.revision,
              ),
              createdAt: DateTime.now(),
            ),
          );
        }
        await (update(
          localResumes,
        )..where((row) => row.localId.equals(resume.localId))).write(
          LocalResumesCompanion(
            workspaceId: Value(workspaceId),
            syncStatus: const Value('pending'),
          ),
        );
      }
    });
  }

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

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
