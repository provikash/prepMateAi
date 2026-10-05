// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedResourcesTable extends CachedResources
    with TableInfo<$CachedResourcesTable, CachedResource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedResourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _staleAtMeta = const VerificationMeta(
    'staleAt',
  );
  @override
  late final GeneratedColumn<DateTime> staleAt = GeneratedColumn<DateTime>(
    'stale_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resourceVersionMeta = const VerificationMeta(
    'resourceVersion',
  );
  @override
  late final GeneratedColumn<String> resourceVersion = GeneratedColumn<String>(
    'resource_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cacheSchemaMeta = const VerificationMeta(
    'cacheSchema',
  );
  @override
  late final GeneratedColumn<int> cacheSchema = GeneratedColumn<int>(
    'cache_schema',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheKey,
    payload,
    userId,
    createdAt,
    expiresAt,
    staleAt,
    etag,
    resourceVersion,
    cacheSchema,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_resources';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedResource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('stale_at')) {
      context.handle(
        _staleAtMeta,
        staleAt.isAcceptableOrUnknown(data['stale_at']!, _staleAtMeta),
      );
    } else if (isInserting) {
      context.missing(_staleAtMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('resource_version')) {
      context.handle(
        _resourceVersionMeta,
        resourceVersion.isAcceptableOrUnknown(
          data['resource_version']!,
          _resourceVersionMeta,
        ),
      );
    }
    if (data.containsKey('cache_schema')) {
      context.handle(
        _cacheSchemaMeta,
        cacheSchema.isAcceptableOrUnknown(
          data['cache_schema']!,
          _cacheSchemaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cacheSchemaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  CachedResource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedResource(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      staleAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}stale_at'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      resourceVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_version'],
      ),
      cacheSchema: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cache_schema'],
      )!,
    );
  }

  @override
  $CachedResourcesTable createAlias(String alias) {
    return $CachedResourcesTable(attachedDatabase, alias);
  }
}

class CachedResource extends DataClass implements Insertable<CachedResource> {
  final String cacheKey;
  final String payload;
  final String? userId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime staleAt;
  final String? etag;
  final String? resourceVersion;
  final int cacheSchema;
  const CachedResource({
    required this.cacheKey,
    required this.payload,
    this.userId,
    required this.createdAt,
    required this.expiresAt,
    required this.staleAt,
    this.etag,
    this.resourceVersion,
    required this.cacheSchema,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    map['stale_at'] = Variable<DateTime>(staleAt);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || resourceVersion != null) {
      map['resource_version'] = Variable<String>(resourceVersion);
    }
    map['cache_schema'] = Variable<int>(cacheSchema);
    return map;
  }

  CachedResourcesCompanion toCompanion(bool nullToAbsent) {
    return CachedResourcesCompanion(
      cacheKey: Value(cacheKey),
      payload: Value(payload),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      createdAt: Value(createdAt),
      expiresAt: Value(expiresAt),
      staleAt: Value(staleAt),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      resourceVersion: resourceVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceVersion),
      cacheSchema: Value(cacheSchema),
    );
  }

  factory CachedResource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedResource(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      payload: serializer.fromJson<String>(json['payload']),
      userId: serializer.fromJson<String?>(json['userId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      staleAt: serializer.fromJson<DateTime>(json['staleAt']),
      etag: serializer.fromJson<String?>(json['etag']),
      resourceVersion: serializer.fromJson<String?>(json['resourceVersion']),
      cacheSchema: serializer.fromJson<int>(json['cacheSchema']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'payload': serializer.toJson<String>(payload),
      'userId': serializer.toJson<String?>(userId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'staleAt': serializer.toJson<DateTime>(staleAt),
      'etag': serializer.toJson<String?>(etag),
      'resourceVersion': serializer.toJson<String?>(resourceVersion),
      'cacheSchema': serializer.toJson<int>(cacheSchema),
    };
  }

  CachedResource copyWith({
    String? cacheKey,
    String? payload,
    Value<String?> userId = const Value.absent(),
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? staleAt,
    Value<String?> etag = const Value.absent(),
    Value<String?> resourceVersion = const Value.absent(),
    int? cacheSchema,
  }) => CachedResource(
    cacheKey: cacheKey ?? this.cacheKey,
    payload: payload ?? this.payload,
    userId: userId.present ? userId.value : this.userId,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    staleAt: staleAt ?? this.staleAt,
    etag: etag.present ? etag.value : this.etag,
    resourceVersion: resourceVersion.present
        ? resourceVersion.value
        : this.resourceVersion,
    cacheSchema: cacheSchema ?? this.cacheSchema,
  );
  CachedResource copyWithCompanion(CachedResourcesCompanion data) {
    return CachedResource(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      payload: data.payload.present ? data.payload.value : this.payload,
      userId: data.userId.present ? data.userId.value : this.userId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      staleAt: data.staleAt.present ? data.staleAt.value : this.staleAt,
      etag: data.etag.present ? data.etag.value : this.etag,
      resourceVersion: data.resourceVersion.present
          ? data.resourceVersion.value
          : this.resourceVersion,
      cacheSchema: data.cacheSchema.present
          ? data.cacheSchema.value
          : this.cacheSchema,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedResource(')
          ..write('cacheKey: $cacheKey, ')
          ..write('payload: $payload, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('staleAt: $staleAt, ')
          ..write('etag: $etag, ')
          ..write('resourceVersion: $resourceVersion, ')
          ..write('cacheSchema: $cacheSchema')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cacheKey,
    payload,
    userId,
    createdAt,
    expiresAt,
    staleAt,
    etag,
    resourceVersion,
    cacheSchema,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedResource &&
          other.cacheKey == this.cacheKey &&
          other.payload == this.payload &&
          other.userId == this.userId &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt &&
          other.staleAt == this.staleAt &&
          other.etag == this.etag &&
          other.resourceVersion == this.resourceVersion &&
          other.cacheSchema == this.cacheSchema);
}

class CachedResourcesCompanion extends UpdateCompanion<CachedResource> {
  final Value<String> cacheKey;
  final Value<String> payload;
  final Value<String?> userId;
  final Value<DateTime> createdAt;
  final Value<DateTime> expiresAt;
  final Value<DateTime> staleAt;
  final Value<String?> etag;
  final Value<String?> resourceVersion;
  final Value<int> cacheSchema;
  final Value<int> rowid;
  const CachedResourcesCompanion({
    this.cacheKey = const Value.absent(),
    this.payload = const Value.absent(),
    this.userId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.staleAt = const Value.absent(),
    this.etag = const Value.absent(),
    this.resourceVersion = const Value.absent(),
    this.cacheSchema = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedResourcesCompanion.insert({
    required String cacheKey,
    required String payload,
    this.userId = const Value.absent(),
    required DateTime createdAt,
    required DateTime expiresAt,
    required DateTime staleAt,
    this.etag = const Value.absent(),
    this.resourceVersion = const Value.absent(),
    required int cacheSchema,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       payload = Value(payload),
       createdAt = Value(createdAt),
       expiresAt = Value(expiresAt),
       staleAt = Value(staleAt),
       cacheSchema = Value(cacheSchema);
  static Insertable<CachedResource> custom({
    Expression<String>? cacheKey,
    Expression<String>? payload,
    Expression<String>? userId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? staleAt,
    Expression<String>? etag,
    Expression<String>? resourceVersion,
    Expression<int>? cacheSchema,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (payload != null) 'payload': payload,
      if (userId != null) 'user_id': userId,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (staleAt != null) 'stale_at': staleAt,
      if (etag != null) 'etag': etag,
      if (resourceVersion != null) 'resource_version': resourceVersion,
      if (cacheSchema != null) 'cache_schema': cacheSchema,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedResourcesCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? payload,
    Value<String?>? userId,
    Value<DateTime>? createdAt,
    Value<DateTime>? expiresAt,
    Value<DateTime>? staleAt,
    Value<String?>? etag,
    Value<String?>? resourceVersion,
    Value<int>? cacheSchema,
    Value<int>? rowid,
  }) {
    return CachedResourcesCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      payload: payload ?? this.payload,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      staleAt: staleAt ?? this.staleAt,
      etag: etag ?? this.etag,
      resourceVersion: resourceVersion ?? this.resourceVersion,
      cacheSchema: cacheSchema ?? this.cacheSchema,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (staleAt.present) {
      map['stale_at'] = Variable<DateTime>(staleAt.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (resourceVersion.present) {
      map['resource_version'] = Variable<String>(resourceVersion.value);
    }
    if (cacheSchema.present) {
      map['cache_schema'] = Variable<int>(cacheSchema.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedResourcesCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('payload: $payload, ')
          ..write('userId: $userId, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('staleAt: $staleAt, ')
          ..write('etag: $etag, ')
          ..write('resourceVersion: $resourceVersion, ')
          ..write('cacheSchema: $cacheSchema, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalResumesTable extends LocalResumes
    with TableInfo<$LocalResumesTable, LocalResume> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalResumesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _tombstoneMeta = const VerificationMeta(
    'tombstone',
  );
  @override
  late final GeneratedColumn<bool> tombstone = GeneratedColumn<bool>(
    'tombstone',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tombstone" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _conflictOfMeta = const VerificationMeta(
    'conflictOf',
  );
  @override
  late final GeneratedColumn<String> conflictOf = GeneratedColumn<String>(
    'conflict_of',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failureKindMeta = const VerificationMeta(
    'failureKind',
  );
  @override
  late final GeneratedColumn<String> failureKind = GeneratedColumn<String>(
    'failure_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    userId,
    remoteId,
    payload,
    revision,
    syncStatus,
    tombstone,
    conflictOf,
    failureKind,
    lastError,
    createdAt,
    updatedAt,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_resumes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalResume> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('tombstone')) {
      context.handle(
        _tombstoneMeta,
        tombstone.isAcceptableOrUnknown(data['tombstone']!, _tombstoneMeta),
      );
    }
    if (data.containsKey('conflict_of')) {
      context.handle(
        _conflictOfMeta,
        conflictOf.isAcceptableOrUnknown(data['conflict_of']!, _conflictOfMeta),
      );
    }
    if (data.containsKey('failure_kind')) {
      context.handle(
        _failureKindMeta,
        failureKind.isAcceptableOrUnknown(
          data['failure_kind']!,
          _failureKindMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LocalResume map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalResume(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      tombstone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tombstone'],
      )!,
      conflictOf: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conflict_of'],
      ),
      failureKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_kind'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $LocalResumesTable createAlias(String alias) {
    return $LocalResumesTable(attachedDatabase, alias);
  }
}

class LocalResume extends DataClass implements Insertable<LocalResume> {
  final String localId;
  final String userId;
  final String? remoteId;
  final String payload;
  final int revision;
  final String syncStatus;
  final bool tombstone;
  final String? conflictOf;
  final String? failureKind;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;
  const LocalResume({
    required this.localId,
    required this.userId,
    this.remoteId,
    required this.payload,
    required this.revision,
    required this.syncStatus,
    required this.tombstone,
    this.conflictOf,
    this.failureKind,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['payload'] = Variable<String>(payload);
    map['revision'] = Variable<int>(revision);
    map['sync_status'] = Variable<String>(syncStatus);
    map['tombstone'] = Variable<bool>(tombstone);
    if (!nullToAbsent || conflictOf != null) {
      map['conflict_of'] = Variable<String>(conflictOf);
    }
    if (!nullToAbsent || failureKind != null) {
      map['failure_kind'] = Variable<String>(failureKind);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  LocalResumesCompanion toCompanion(bool nullToAbsent) {
    return LocalResumesCompanion(
      localId: Value(localId),
      userId: Value(userId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      payload: Value(payload),
      revision: Value(revision),
      syncStatus: Value(syncStatus),
      tombstone: Value(tombstone),
      conflictOf: conflictOf == null && nullToAbsent
          ? const Value.absent()
          : Value(conflictOf),
      failureKind: failureKind == null && nullToAbsent
          ? const Value.absent()
          : Value(failureKind),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory LocalResume.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalResume(
      localId: serializer.fromJson<String>(json['localId']),
      userId: serializer.fromJson<String>(json['userId']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      payload: serializer.fromJson<String>(json['payload']),
      revision: serializer.fromJson<int>(json['revision']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      tombstone: serializer.fromJson<bool>(json['tombstone']),
      conflictOf: serializer.fromJson<String?>(json['conflictOf']),
      failureKind: serializer.fromJson<String?>(json['failureKind']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'userId': serializer.toJson<String>(userId),
      'remoteId': serializer.toJson<String?>(remoteId),
      'payload': serializer.toJson<String>(payload),
      'revision': serializer.toJson<int>(revision),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'tombstone': serializer.toJson<bool>(tombstone),
      'conflictOf': serializer.toJson<String?>(conflictOf),
      'failureKind': serializer.toJson<String?>(failureKind),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  LocalResume copyWith({
    String? localId,
    String? userId,
    Value<String?> remoteId = const Value.absent(),
    String? payload,
    int? revision,
    String? syncStatus,
    bool? tombstone,
    Value<String?> conflictOf = const Value.absent(),
    Value<String?> failureKind = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => LocalResume(
    localId: localId ?? this.localId,
    userId: userId ?? this.userId,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    payload: payload ?? this.payload,
    revision: revision ?? this.revision,
    syncStatus: syncStatus ?? this.syncStatus,
    tombstone: tombstone ?? this.tombstone,
    conflictOf: conflictOf.present ? conflictOf.value : this.conflictOf,
    failureKind: failureKind.present ? failureKind.value : this.failureKind,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  LocalResume copyWithCompanion(LocalResumesCompanion data) {
    return LocalResume(
      localId: data.localId.present ? data.localId.value : this.localId,
      userId: data.userId.present ? data.userId.value : this.userId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      payload: data.payload.present ? data.payload.value : this.payload,
      revision: data.revision.present ? data.revision.value : this.revision,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      tombstone: data.tombstone.present ? data.tombstone.value : this.tombstone,
      conflictOf: data.conflictOf.present
          ? data.conflictOf.value
          : this.conflictOf,
      failureKind: data.failureKind.present
          ? data.failureKind.value
          : this.failureKind,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalResume(')
          ..write('localId: $localId, ')
          ..write('userId: $userId, ')
          ..write('remoteId: $remoteId, ')
          ..write('payload: $payload, ')
          ..write('revision: $revision, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('tombstone: $tombstone, ')
          ..write('conflictOf: $conflictOf, ')
          ..write('failureKind: $failureKind, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    userId,
    remoteId,
    payload,
    revision,
    syncStatus,
    tombstone,
    conflictOf,
    failureKind,
    lastError,
    createdAt,
    updatedAt,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalResume &&
          other.localId == this.localId &&
          other.userId == this.userId &&
          other.remoteId == this.remoteId &&
          other.payload == this.payload &&
          other.revision == this.revision &&
          other.syncStatus == this.syncStatus &&
          other.tombstone == this.tombstone &&
          other.conflictOf == this.conflictOf &&
          other.failureKind == this.failureKind &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class LocalResumesCompanion extends UpdateCompanion<LocalResume> {
  final Value<String> localId;
  final Value<String> userId;
  final Value<String?> remoteId;
  final Value<String> payload;
  final Value<int> revision;
  final Value<String> syncStatus;
  final Value<bool> tombstone;
  final Value<String?> conflictOf;
  final Value<String?> failureKind;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const LocalResumesCompanion({
    this.localId = const Value.absent(),
    this.userId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.payload = const Value.absent(),
    this.revision = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.tombstone = const Value.absent(),
    this.conflictOf = const Value.absent(),
    this.failureKind = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalResumesCompanion.insert({
    required String localId,
    required String userId,
    this.remoteId = const Value.absent(),
    required String payload,
    this.revision = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.tombstone = const Value.absent(),
    this.conflictOf = const Value.absent(),
    this.failureKind = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       userId = Value(userId),
       payload = Value(payload),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalResume> custom({
    Expression<String>? localId,
    Expression<String>? userId,
    Expression<String>? remoteId,
    Expression<String>? payload,
    Expression<int>? revision,
    Expression<String>? syncStatus,
    Expression<bool>? tombstone,
    Expression<String>? conflictOf,
    Expression<String>? failureKind,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (userId != null) 'user_id': userId,
      if (remoteId != null) 'remote_id': remoteId,
      if (payload != null) 'payload': payload,
      if (revision != null) 'revision': revision,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (tombstone != null) 'tombstone': tombstone,
      if (conflictOf != null) 'conflict_of': conflictOf,
      if (failureKind != null) 'failure_kind': failureKind,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalResumesCompanion copyWith({
    Value<String>? localId,
    Value<String>? userId,
    Value<String?>? remoteId,
    Value<String>? payload,
    Value<int>? revision,
    Value<String>? syncStatus,
    Value<bool>? tombstone,
    Value<String?>? conflictOf,
    Value<String?>? failureKind,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return LocalResumesCompanion(
      localId: localId ?? this.localId,
      userId: userId ?? this.userId,
      remoteId: remoteId ?? this.remoteId,
      payload: payload ?? this.payload,
      revision: revision ?? this.revision,
      syncStatus: syncStatus ?? this.syncStatus,
      tombstone: tombstone ?? this.tombstone,
      conflictOf: conflictOf ?? this.conflictOf,
      failureKind: failureKind ?? this.failureKind,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (tombstone.present) {
      map['tombstone'] = Variable<bool>(tombstone.value);
    }
    if (conflictOf.present) {
      map['conflict_of'] = Variable<String>(conflictOf.value);
    }
    if (failureKind.present) {
      map['failure_kind'] = Variable<String>(failureKind.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalResumesCompanion(')
          ..write('localId: $localId, ')
          ..write('userId: $userId, ')
          ..write('remoteId: $remoteId, ')
          ..write('payload: $payload, ')
          ..write('revision: $revision, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('tombstone: $tombstone, ')
          ..write('conflictOf: $conflictOf, ')
          ..write('failureKind: $failureKind, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MutationOutboxTable extends MutationOutbox
    with TableInfo<$MutationOutboxTable, MutationOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MutationOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityLocalIdMeta = const VerificationMeta(
    'entityLocalId',
  );
  @override
  late final GeneratedColumn<String> entityLocalId = GeneratedColumn<String>(
    'entity_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseRevisionMeta = const VerificationMeta(
    'baseRevision',
  );
  @override
  late final GeneratedColumn<int> baseRevision = GeneratedColumn<int>(
    'base_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _permanentFailureMeta = const VerificationMeta(
    'permanentFailure',
  );
  @override
  late final GeneratedColumn<bool> permanentFailure = GeneratedColumn<bool>(
    'permanent_failure',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("permanent_failure" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    entityType,
    entityLocalId,
    operation,
    payload,
    baseRevision,
    attemptCount,
    nextAttemptAt,
    lastError,
    permanentFailure,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mutation_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<MutationOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_local_id')) {
      context.handle(
        _entityLocalIdMeta,
        entityLocalId.isAcceptableOrUnknown(
          data['entity_local_id']!,
          _entityLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityLocalIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('base_revision')) {
      context.handle(
        _baseRevisionMeta,
        baseRevision.isAcceptableOrUnknown(
          data['base_revision']!,
          _baseRevisionMeta,
        ),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('permanent_failure')) {
      context.handle(
        _permanentFailureMeta,
        permanentFailure.isAcceptableOrUnknown(
          data['permanent_failure']!,
          _permanentFailureMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MutationOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MutationOutboxData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_local_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      baseRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_revision'],
      ),
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      permanentFailure: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}permanent_failure'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MutationOutboxTable createAlias(String alias) {
    return $MutationOutboxTable(attachedDatabase, alias);
  }
}

class MutationOutboxData extends DataClass
    implements Insertable<MutationOutboxData> {
  final int id;
  final String userId;
  final String entityType;
  final String entityLocalId;
  final String operation;
  final String payload;
  final int? baseRevision;
  final int attemptCount;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final bool permanentFailure;
  final DateTime createdAt;
  const MutationOutboxData({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityLocalId,
    required this.operation,
    required this.payload,
    this.baseRevision,
    required this.attemptCount,
    this.nextAttemptAt,
    this.lastError,
    required this.permanentFailure,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_local_id'] = Variable<String>(entityLocalId);
    map['operation'] = Variable<String>(operation);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || baseRevision != null) {
      map['base_revision'] = Variable<int>(baseRevision);
    }
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['permanent_failure'] = Variable<bool>(permanentFailure);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MutationOutboxCompanion toCompanion(bool nullToAbsent) {
    return MutationOutboxCompanion(
      id: Value(id),
      userId: Value(userId),
      entityType: Value(entityType),
      entityLocalId: Value(entityLocalId),
      operation: Value(operation),
      payload: Value(payload),
      baseRevision: baseRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(baseRevision),
      attemptCount: Value(attemptCount),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      permanentFailure: Value(permanentFailure),
      createdAt: Value(createdAt),
    );
  }

  factory MutationOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MutationOutboxData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityLocalId: serializer.fromJson<String>(json['entityLocalId']),
      operation: serializer.fromJson<String>(json['operation']),
      payload: serializer.fromJson<String>(json['payload']),
      baseRevision: serializer.fromJson<int?>(json['baseRevision']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      permanentFailure: serializer.fromJson<bool>(json['permanentFailure']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'entityType': serializer.toJson<String>(entityType),
      'entityLocalId': serializer.toJson<String>(entityLocalId),
      'operation': serializer.toJson<String>(operation),
      'payload': serializer.toJson<String>(payload),
      'baseRevision': serializer.toJson<int?>(baseRevision),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'permanentFailure': serializer.toJson<bool>(permanentFailure),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MutationOutboxData copyWith({
    int? id,
    String? userId,
    String? entityType,
    String? entityLocalId,
    String? operation,
    String? payload,
    Value<int?> baseRevision = const Value.absent(),
    int? attemptCount,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    bool? permanentFailure,
    DateTime? createdAt,
  }) => MutationOutboxData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    entityType: entityType ?? this.entityType,
    entityLocalId: entityLocalId ?? this.entityLocalId,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    baseRevision: baseRevision.present ? baseRevision.value : this.baseRevision,
    attemptCount: attemptCount ?? this.attemptCount,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    permanentFailure: permanentFailure ?? this.permanentFailure,
    createdAt: createdAt ?? this.createdAt,
  );
  MutationOutboxData copyWithCompanion(MutationOutboxCompanion data) {
    return MutationOutboxData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityLocalId: data.entityLocalId.present
          ? data.entityLocalId.value
          : this.entityLocalId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      baseRevision: data.baseRevision.present
          ? data.baseRevision.value
          : this.baseRevision,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      permanentFailure: data.permanentFailure.present
          ? data.permanentFailure.value
          : this.permanentFailure,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MutationOutboxData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('entityType: $entityType, ')
          ..write('entityLocalId: $entityLocalId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('permanentFailure: $permanentFailure, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    entityType,
    entityLocalId,
    operation,
    payload,
    baseRevision,
    attemptCount,
    nextAttemptAt,
    lastError,
    permanentFailure,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MutationOutboxData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.entityType == this.entityType &&
          other.entityLocalId == this.entityLocalId &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.baseRevision == this.baseRevision &&
          other.attemptCount == this.attemptCount &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.permanentFailure == this.permanentFailure &&
          other.createdAt == this.createdAt);
}

class MutationOutboxCompanion extends UpdateCompanion<MutationOutboxData> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> entityType;
  final Value<String> entityLocalId;
  final Value<String> operation;
  final Value<String> payload;
  final Value<int?> baseRevision;
  final Value<int> attemptCount;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastError;
  final Value<bool> permanentFailure;
  final Value<DateTime> createdAt;
  const MutationOutboxCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityLocalId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.baseRevision = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.permanentFailure = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MutationOutboxCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String entityType,
    required String entityLocalId,
    required String operation,
    required String payload,
    this.baseRevision = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.permanentFailure = const Value.absent(),
    required DateTime createdAt,
  }) : userId = Value(userId),
       entityType = Value(entityType),
       entityLocalId = Value(entityLocalId),
       operation = Value(operation),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<MutationOutboxData> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? entityType,
    Expression<String>? entityLocalId,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<int>? baseRevision,
    Expression<int>? attemptCount,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<bool>? permanentFailure,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (entityType != null) 'entity_type': entityType,
      if (entityLocalId != null) 'entity_local_id': entityLocalId,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (baseRevision != null) 'base_revision': baseRevision,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (permanentFailure != null) 'permanent_failure': permanentFailure,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MutationOutboxCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? entityType,
    Value<String>? entityLocalId,
    Value<String>? operation,
    Value<String>? payload,
    Value<int?>? baseRevision,
    Value<int>? attemptCount,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastError,
    Value<bool>? permanentFailure,
    Value<DateTime>? createdAt,
  }) {
    return MutationOutboxCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entityType: entityType ?? this.entityType,
      entityLocalId: entityLocalId ?? this.entityLocalId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      baseRevision: baseRevision ?? this.baseRevision,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      permanentFailure: permanentFailure ?? this.permanentFailure,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityLocalId.present) {
      map['entity_local_id'] = Variable<String>(entityLocalId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (baseRevision.present) {
      map['base_revision'] = Variable<int>(baseRevision.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (permanentFailure.present) {
      map['permanent_failure'] = Variable<bool>(permanentFailure.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MutationOutboxCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('entityType: $entityType, ')
          ..write('entityLocalId: $entityLocalId, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('permanentFailure: $permanentFailure, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $OptimizationSnapshotsTable extends OptimizationSnapshots
    with TableInfo<$OptimizationSnapshotsTable, OptimizationSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OptimizationSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _staleMeta = const VerificationMeta('stale');
  @override
  late final GeneratedColumn<bool> stale = GeneratedColumn<bool>(
    'stale',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("stale" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheKey,
    userId,
    sessionId,
    payload,
    stale,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'optimization_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<OptimizationSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('stale')) {
      context.handle(
        _staleMeta,
        stale.isAcceptableOrUnknown(data['stale']!, _staleMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  OptimizationSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OptimizationSnapshot(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      stale: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}stale'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $OptimizationSnapshotsTable createAlias(String alias) {
    return $OptimizationSnapshotsTable(attachedDatabase, alias);
  }
}

class OptimizationSnapshot extends DataClass
    implements Insertable<OptimizationSnapshot> {
  final String cacheKey;
  final String userId;
  final String sessionId;
  final String payload;
  final bool stale;
  final DateTime updatedAt;
  const OptimizationSnapshot({
    required this.cacheKey,
    required this.userId,
    required this.sessionId,
    required this.payload,
    required this.stale,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['user_id'] = Variable<String>(userId);
    map['session_id'] = Variable<String>(sessionId);
    map['payload'] = Variable<String>(payload);
    map['stale'] = Variable<bool>(stale);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OptimizationSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return OptimizationSnapshotsCompanion(
      cacheKey: Value(cacheKey),
      userId: Value(userId),
      sessionId: Value(sessionId),
      payload: Value(payload),
      stale: Value(stale),
      updatedAt: Value(updatedAt),
    );
  }

  factory OptimizationSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OptimizationSnapshot(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      userId: serializer.fromJson<String>(json['userId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      payload: serializer.fromJson<String>(json['payload']),
      stale: serializer.fromJson<bool>(json['stale']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'userId': serializer.toJson<String>(userId),
      'sessionId': serializer.toJson<String>(sessionId),
      'payload': serializer.toJson<String>(payload),
      'stale': serializer.toJson<bool>(stale),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OptimizationSnapshot copyWith({
    String? cacheKey,
    String? userId,
    String? sessionId,
    String? payload,
    bool? stale,
    DateTime? updatedAt,
  }) => OptimizationSnapshot(
    cacheKey: cacheKey ?? this.cacheKey,
    userId: userId ?? this.userId,
    sessionId: sessionId ?? this.sessionId,
    payload: payload ?? this.payload,
    stale: stale ?? this.stale,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OptimizationSnapshot copyWithCompanion(OptimizationSnapshotsCompanion data) {
    return OptimizationSnapshot(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      userId: data.userId.present ? data.userId.value : this.userId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      payload: data.payload.present ? data.payload.value : this.payload,
      stale: data.stale.present ? data.stale.value : this.stale,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OptimizationSnapshot(')
          ..write('cacheKey: $cacheKey, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('payload: $payload, ')
          ..write('stale: $stale, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(cacheKey, userId, sessionId, payload, stale, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OptimizationSnapshot &&
          other.cacheKey == this.cacheKey &&
          other.userId == this.userId &&
          other.sessionId == this.sessionId &&
          other.payload == this.payload &&
          other.stale == this.stale &&
          other.updatedAt == this.updatedAt);
}

class OptimizationSnapshotsCompanion
    extends UpdateCompanion<OptimizationSnapshot> {
  final Value<String> cacheKey;
  final Value<String> userId;
  final Value<String> sessionId;
  final Value<String> payload;
  final Value<bool> stale;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const OptimizationSnapshotsCompanion({
    this.cacheKey = const Value.absent(),
    this.userId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.payload = const Value.absent(),
    this.stale = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OptimizationSnapshotsCompanion.insert({
    required String cacheKey,
    required String userId,
    required String sessionId,
    required String payload,
    this.stale = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       userId = Value(userId),
       sessionId = Value(sessionId),
       payload = Value(payload),
       updatedAt = Value(updatedAt);
  static Insertable<OptimizationSnapshot> custom({
    Expression<String>? cacheKey,
    Expression<String>? userId,
    Expression<String>? sessionId,
    Expression<String>? payload,
    Expression<bool>? stale,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (userId != null) 'user_id': userId,
      if (sessionId != null) 'session_id': sessionId,
      if (payload != null) 'payload': payload,
      if (stale != null) 'stale': stale,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OptimizationSnapshotsCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? userId,
    Value<String>? sessionId,
    Value<String>? payload,
    Value<bool>? stale,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return OptimizationSnapshotsCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      payload: payload ?? this.payload,
      stale: stale ?? this.stale,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (stale.present) {
      map['stale'] = Variable<bool>(stale.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OptimizationSnapshotsCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('userId: $userId, ')
          ..write('sessionId: $sessionId, ')
          ..write('payload: $payload, ')
          ..write('stale: $stale, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncEventsTable extends SyncEvents
    with TableInfo<$SyncEventsTable, SyncEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processedMeta = const VerificationMeta(
    'processed',
  );
  @override
  late final GeneratedColumn<int> processed = GeneratedColumn<int>(
    'processed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _failedMeta = const VerificationMeta('failed');
  @override
  late final GeneratedColumn<int> failed = GeneratedColumn<int>(
    'failed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _detailsMeta = const VerificationMeta(
    'details',
  );
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    occurredAt,
    source,
    outcome,
    processed,
    failed,
    details,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('processed')) {
      context.handle(
        _processedMeta,
        processed.isAcceptableOrUnknown(data['processed']!, _processedMeta),
      );
    }
    if (data.containsKey('failed')) {
      context.handle(
        _failedMeta,
        failed.isAcceptableOrUnknown(data['failed']!, _failedMeta),
      );
    }
    if (data.containsKey('details')) {
      context.handle(
        _detailsMeta,
        details.isAcceptableOrUnknown(data['details']!, _detailsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      processed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}processed'],
      )!,
      failed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed'],
      )!,
      details: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details'],
      ),
    );
  }

  @override
  $SyncEventsTable createAlias(String alias) {
    return $SyncEventsTable(attachedDatabase, alias);
  }
}

class SyncEvent extends DataClass implements Insertable<SyncEvent> {
  final int id;
  final DateTime occurredAt;
  final String source;
  final String outcome;
  final int processed;
  final int failed;
  final String? details;
  const SyncEvent({
    required this.id,
    required this.occurredAt,
    required this.source,
    required this.outcome,
    required this.processed,
    required this.failed,
    this.details,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['source'] = Variable<String>(source);
    map['outcome'] = Variable<String>(outcome);
    map['processed'] = Variable<int>(processed);
    map['failed'] = Variable<int>(failed);
    if (!nullToAbsent || details != null) {
      map['details'] = Variable<String>(details);
    }
    return map;
  }

  SyncEventsCompanion toCompanion(bool nullToAbsent) {
    return SyncEventsCompanion(
      id: Value(id),
      occurredAt: Value(occurredAt),
      source: Value(source),
      outcome: Value(outcome),
      processed: Value(processed),
      failed: Value(failed),
      details: details == null && nullToAbsent
          ? const Value.absent()
          : Value(details),
    );
  }

  factory SyncEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncEvent(
      id: serializer.fromJson<int>(json['id']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      source: serializer.fromJson<String>(json['source']),
      outcome: serializer.fromJson<String>(json['outcome']),
      processed: serializer.fromJson<int>(json['processed']),
      failed: serializer.fromJson<int>(json['failed']),
      details: serializer.fromJson<String?>(json['details']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'source': serializer.toJson<String>(source),
      'outcome': serializer.toJson<String>(outcome),
      'processed': serializer.toJson<int>(processed),
      'failed': serializer.toJson<int>(failed),
      'details': serializer.toJson<String?>(details),
    };
  }

  SyncEvent copyWith({
    int? id,
    DateTime? occurredAt,
    String? source,
    String? outcome,
    int? processed,
    int? failed,
    Value<String?> details = const Value.absent(),
  }) => SyncEvent(
    id: id ?? this.id,
    occurredAt: occurredAt ?? this.occurredAt,
    source: source ?? this.source,
    outcome: outcome ?? this.outcome,
    processed: processed ?? this.processed,
    failed: failed ?? this.failed,
    details: details.present ? details.value : this.details,
  );
  SyncEvent copyWithCompanion(SyncEventsCompanion data) {
    return SyncEvent(
      id: data.id.present ? data.id.value : this.id,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      source: data.source.present ? data.source.value : this.source,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      processed: data.processed.present ? data.processed.value : this.processed,
      failed: data.failed.present ? data.failed.value : this.failed,
      details: data.details.present ? data.details.value : this.details,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncEvent(')
          ..write('id: $id, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('source: $source, ')
          ..write('outcome: $outcome, ')
          ..write('processed: $processed, ')
          ..write('failed: $failed, ')
          ..write('details: $details')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, occurredAt, source, outcome, processed, failed, details);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncEvent &&
          other.id == this.id &&
          other.occurredAt == this.occurredAt &&
          other.source == this.source &&
          other.outcome == this.outcome &&
          other.processed == this.processed &&
          other.failed == this.failed &&
          other.details == this.details);
}

class SyncEventsCompanion extends UpdateCompanion<SyncEvent> {
  final Value<int> id;
  final Value<DateTime> occurredAt;
  final Value<String> source;
  final Value<String> outcome;
  final Value<int> processed;
  final Value<int> failed;
  final Value<String?> details;
  const SyncEventsCompanion({
    this.id = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.source = const Value.absent(),
    this.outcome = const Value.absent(),
    this.processed = const Value.absent(),
    this.failed = const Value.absent(),
    this.details = const Value.absent(),
  });
  SyncEventsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime occurredAt,
    required String source,
    required String outcome,
    this.processed = const Value.absent(),
    this.failed = const Value.absent(),
    this.details = const Value.absent(),
  }) : occurredAt = Value(occurredAt),
       source = Value(source),
       outcome = Value(outcome);
  static Insertable<SyncEvent> custom({
    Expression<int>? id,
    Expression<DateTime>? occurredAt,
    Expression<String>? source,
    Expression<String>? outcome,
    Expression<int>? processed,
    Expression<int>? failed,
    Expression<String>? details,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (source != null) 'source': source,
      if (outcome != null) 'outcome': outcome,
      if (processed != null) 'processed': processed,
      if (failed != null) 'failed': failed,
      if (details != null) 'details': details,
    });
  }

  SyncEventsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? occurredAt,
    Value<String>? source,
    Value<String>? outcome,
    Value<int>? processed,
    Value<int>? failed,
    Value<String?>? details,
  }) {
    return SyncEventsCompanion(
      id: id ?? this.id,
      occurredAt: occurredAt ?? this.occurredAt,
      source: source ?? this.source,
      outcome: outcome ?? this.outcome,
      processed: processed ?? this.processed,
      failed: failed ?? this.failed,
      details: details ?? this.details,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (processed.present) {
      map['processed'] = Variable<int>(processed.value);
    }
    if (failed.present) {
      map['failed'] = Variable<int>(failed.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncEventsCompanion(')
          ..write('id: $id, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('source: $source, ')
          ..write('outcome: $outcome, ')
          ..write('processed: $processed, ')
          ..write('failed: $failed, ')
          ..write('details: $details')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedResourcesTable cachedResources = $CachedResourcesTable(
    this,
  );
  late final $LocalResumesTable localResumes = $LocalResumesTable(this);
  late final $MutationOutboxTable mutationOutbox = $MutationOutboxTable(this);
  late final $OptimizationSnapshotsTable optimizationSnapshots =
      $OptimizationSnapshotsTable(this);
  late final $SyncEventsTable syncEvents = $SyncEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedResources,
    localResumes,
    mutationOutbox,
    optimizationSnapshots,
    syncEvents,
  ];
}

typedef $$CachedResourcesTableCreateCompanionBuilder =
    CachedResourcesCompanion Function({
      required String cacheKey,
      required String payload,
      Value<String?> userId,
      required DateTime createdAt,
      required DateTime expiresAt,
      required DateTime staleAt,
      Value<String?> etag,
      Value<String?> resourceVersion,
      required int cacheSchema,
      Value<int> rowid,
    });
typedef $$CachedResourcesTableUpdateCompanionBuilder =
    CachedResourcesCompanion Function({
      Value<String> cacheKey,
      Value<String> payload,
      Value<String?> userId,
      Value<DateTime> createdAt,
      Value<DateTime> expiresAt,
      Value<DateTime> staleAt,
      Value<String?> etag,
      Value<String?> resourceVersion,
      Value<int> cacheSchema,
      Value<int> rowid,
    });

class $$CachedResourcesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedResourcesTable> {
  $$CachedResourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get staleAt => $composableBuilder(
    column: $table.staleAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resourceVersion => $composableBuilder(
    column: $table.resourceVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cacheSchema => $composableBuilder(
    column: $table.cacheSchema,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedResourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedResourcesTable> {
  $$CachedResourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get staleAt => $composableBuilder(
    column: $table.staleAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resourceVersion => $composableBuilder(
    column: $table.resourceVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cacheSchema => $composableBuilder(
    column: $table.cacheSchema,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedResourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedResourcesTable> {
  $$CachedResourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get staleAt =>
      $composableBuilder(column: $table.staleAt, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<String> get resourceVersion => $composableBuilder(
    column: $table.resourceVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cacheSchema => $composableBuilder(
    column: $table.cacheSchema,
    builder: (column) => column,
  );
}

class $$CachedResourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedResourcesTable,
          CachedResource,
          $$CachedResourcesTableFilterComposer,
          $$CachedResourcesTableOrderingComposer,
          $$CachedResourcesTableAnnotationComposer,
          $$CachedResourcesTableCreateCompanionBuilder,
          $$CachedResourcesTableUpdateCompanionBuilder,
          (
            CachedResource,
            BaseReferences<
              _$AppDatabase,
              $CachedResourcesTable,
              CachedResource
            >,
          ),
          CachedResource,
          PrefetchHooks Function()
        > {
  $$CachedResourcesTableTableManager(
    _$AppDatabase db,
    $CachedResourcesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedResourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedResourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedResourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime> staleAt = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<String?> resourceVersion = const Value.absent(),
                Value<int> cacheSchema = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedResourcesCompanion(
                cacheKey: cacheKey,
                payload: payload,
                userId: userId,
                createdAt: createdAt,
                expiresAt: expiresAt,
                staleAt: staleAt,
                etag: etag,
                resourceVersion: resourceVersion,
                cacheSchema: cacheSchema,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String payload,
                Value<String?> userId = const Value.absent(),
                required DateTime createdAt,
                required DateTime expiresAt,
                required DateTime staleAt,
                Value<String?> etag = const Value.absent(),
                Value<String?> resourceVersion = const Value.absent(),
                required int cacheSchema,
                Value<int> rowid = const Value.absent(),
              }) => CachedResourcesCompanion.insert(
                cacheKey: cacheKey,
                payload: payload,
                userId: userId,
                createdAt: createdAt,
                expiresAt: expiresAt,
                staleAt: staleAt,
                etag: etag,
                resourceVersion: resourceVersion,
                cacheSchema: cacheSchema,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedResourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedResourcesTable,
      CachedResource,
      $$CachedResourcesTableFilterComposer,
      $$CachedResourcesTableOrderingComposer,
      $$CachedResourcesTableAnnotationComposer,
      $$CachedResourcesTableCreateCompanionBuilder,
      $$CachedResourcesTableUpdateCompanionBuilder,
      (
        CachedResource,
        BaseReferences<_$AppDatabase, $CachedResourcesTable, CachedResource>,
      ),
      CachedResource,
      PrefetchHooks Function()
    >;
typedef $$LocalResumesTableCreateCompanionBuilder =
    LocalResumesCompanion Function({
      required String localId,
      required String userId,
      Value<String?> remoteId,
      required String payload,
      Value<int> revision,
      Value<String> syncStatus,
      Value<bool> tombstone,
      Value<String?> conflictOf,
      Value<String?> failureKind,
      Value<String?> lastError,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$LocalResumesTableUpdateCompanionBuilder =
    LocalResumesCompanion Function({
      Value<String> localId,
      Value<String> userId,
      Value<String?> remoteId,
      Value<String> payload,
      Value<int> revision,
      Value<String> syncStatus,
      Value<bool> tombstone,
      Value<String?> conflictOf,
      Value<String?> failureKind,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$LocalResumesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalResumesTable> {
  $$LocalResumesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tombstone => $composableBuilder(
    column: $table.tombstone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conflictOf => $composableBuilder(
    column: $table.conflictOf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureKind => $composableBuilder(
    column: $table.failureKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalResumesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalResumesTable> {
  $$LocalResumesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tombstone => $composableBuilder(
    column: $table.tombstone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conflictOf => $composableBuilder(
    column: $table.conflictOf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureKind => $composableBuilder(
    column: $table.failureKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalResumesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalResumesTable> {
  $$LocalResumesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tombstone =>
      $composableBuilder(column: $table.tombstone, builder: (column) => column);

  GeneratedColumn<String> get conflictOf => $composableBuilder(
    column: $table.conflictOf,
    builder: (column) => column,
  );

  GeneratedColumn<String> get failureKind => $composableBuilder(
    column: $table.failureKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$LocalResumesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalResumesTable,
          LocalResume,
          $$LocalResumesTableFilterComposer,
          $$LocalResumesTableOrderingComposer,
          $$LocalResumesTableAnnotationComposer,
          $$LocalResumesTableCreateCompanionBuilder,
          $$LocalResumesTableUpdateCompanionBuilder,
          (
            LocalResume,
            BaseReferences<_$AppDatabase, $LocalResumesTable, LocalResume>,
          ),
          LocalResume,
          PrefetchHooks Function()
        > {
  $$LocalResumesTableTableManager(_$AppDatabase db, $LocalResumesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalResumesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalResumesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalResumesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<bool> tombstone = const Value.absent(),
                Value<String?> conflictOf = const Value.absent(),
                Value<String?> failureKind = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalResumesCompanion(
                localId: localId,
                userId: userId,
                remoteId: remoteId,
                payload: payload,
                revision: revision,
                syncStatus: syncStatus,
                tombstone: tombstone,
                conflictOf: conflictOf,
                failureKind: failureKind,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                required String userId,
                Value<String?> remoteId = const Value.absent(),
                required String payload,
                Value<int> revision = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<bool> tombstone = const Value.absent(),
                Value<String?> conflictOf = const Value.absent(),
                Value<String?> failureKind = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalResumesCompanion.insert(
                localId: localId,
                userId: userId,
                remoteId: remoteId,
                payload: payload,
                revision: revision,
                syncStatus: syncStatus,
                tombstone: tombstone,
                conflictOf: conflictOf,
                failureKind: failureKind,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalResumesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalResumesTable,
      LocalResume,
      $$LocalResumesTableFilterComposer,
      $$LocalResumesTableOrderingComposer,
      $$LocalResumesTableAnnotationComposer,
      $$LocalResumesTableCreateCompanionBuilder,
      $$LocalResumesTableUpdateCompanionBuilder,
      (
        LocalResume,
        BaseReferences<_$AppDatabase, $LocalResumesTable, LocalResume>,
      ),
      LocalResume,
      PrefetchHooks Function()
    >;
typedef $$MutationOutboxTableCreateCompanionBuilder =
    MutationOutboxCompanion Function({
      Value<int> id,
      required String userId,
      required String entityType,
      required String entityLocalId,
      required String operation,
      required String payload,
      Value<int?> baseRevision,
      Value<int> attemptCount,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<bool> permanentFailure,
      required DateTime createdAt,
    });
typedef $$MutationOutboxTableUpdateCompanionBuilder =
    MutationOutboxCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> entityType,
      Value<String> entityLocalId,
      Value<String> operation,
      Value<String> payload,
      Value<int?> baseRevision,
      Value<int> attemptCount,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<bool> permanentFailure,
      Value<DateTime> createdAt,
    });

class $$MutationOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $MutationOutboxTable> {
  $$MutationOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityLocalId => $composableBuilder(
    column: $table.entityLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get permanentFailure => $composableBuilder(
    column: $table.permanentFailure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MutationOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $MutationOutboxTable> {
  $$MutationOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityLocalId => $composableBuilder(
    column: $table.entityLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get permanentFailure => $composableBuilder(
    column: $table.permanentFailure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MutationOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $MutationOutboxTable> {
  $$MutationOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityLocalId => $composableBuilder(
    column: $table.entityLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<bool> get permanentFailure => $composableBuilder(
    column: $table.permanentFailure,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MutationOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MutationOutboxTable,
          MutationOutboxData,
          $$MutationOutboxTableFilterComposer,
          $$MutationOutboxTableOrderingComposer,
          $$MutationOutboxTableAnnotationComposer,
          $$MutationOutboxTableCreateCompanionBuilder,
          $$MutationOutboxTableUpdateCompanionBuilder,
          (
            MutationOutboxData,
            BaseReferences<
              _$AppDatabase,
              $MutationOutboxTable,
              MutationOutboxData
            >,
          ),
          MutationOutboxData,
          PrefetchHooks Function()
        > {
  $$MutationOutboxTableTableManager(
    _$AppDatabase db,
    $MutationOutboxTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MutationOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MutationOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MutationOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityLocalId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int?> baseRevision = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<bool> permanentFailure = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MutationOutboxCompanion(
                id: id,
                userId: userId,
                entityType: entityType,
                entityLocalId: entityLocalId,
                operation: operation,
                payload: payload,
                baseRevision: baseRevision,
                attemptCount: attemptCount,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                permanentFailure: permanentFailure,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String entityType,
                required String entityLocalId,
                required String operation,
                required String payload,
                Value<int?> baseRevision = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<bool> permanentFailure = const Value.absent(),
                required DateTime createdAt,
              }) => MutationOutboxCompanion.insert(
                id: id,
                userId: userId,
                entityType: entityType,
                entityLocalId: entityLocalId,
                operation: operation,
                payload: payload,
                baseRevision: baseRevision,
                attemptCount: attemptCount,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                permanentFailure: permanentFailure,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MutationOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MutationOutboxTable,
      MutationOutboxData,
      $$MutationOutboxTableFilterComposer,
      $$MutationOutboxTableOrderingComposer,
      $$MutationOutboxTableAnnotationComposer,
      $$MutationOutboxTableCreateCompanionBuilder,
      $$MutationOutboxTableUpdateCompanionBuilder,
      (
        MutationOutboxData,
        BaseReferences<_$AppDatabase, $MutationOutboxTable, MutationOutboxData>,
      ),
      MutationOutboxData,
      PrefetchHooks Function()
    >;
typedef $$OptimizationSnapshotsTableCreateCompanionBuilder =
    OptimizationSnapshotsCompanion Function({
      required String cacheKey,
      required String userId,
      required String sessionId,
      required String payload,
      Value<bool> stale,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$OptimizationSnapshotsTableUpdateCompanionBuilder =
    OptimizationSnapshotsCompanion Function({
      Value<String> cacheKey,
      Value<String> userId,
      Value<String> sessionId,
      Value<String> payload,
      Value<bool> stale,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$OptimizationSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $OptimizationSnapshotsTable> {
  $$OptimizationSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get stale => $composableBuilder(
    column: $table.stale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OptimizationSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $OptimizationSnapshotsTable> {
  $$OptimizationSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get stale => $composableBuilder(
    column: $table.stale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OptimizationSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OptimizationSnapshotsTable> {
  $$OptimizationSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<bool> get stale =>
      $composableBuilder(column: $table.stale, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OptimizationSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OptimizationSnapshotsTable,
          OptimizationSnapshot,
          $$OptimizationSnapshotsTableFilterComposer,
          $$OptimizationSnapshotsTableOrderingComposer,
          $$OptimizationSnapshotsTableAnnotationComposer,
          $$OptimizationSnapshotsTableCreateCompanionBuilder,
          $$OptimizationSnapshotsTableUpdateCompanionBuilder,
          (
            OptimizationSnapshot,
            BaseReferences<
              _$AppDatabase,
              $OptimizationSnapshotsTable,
              OptimizationSnapshot
            >,
          ),
          OptimizationSnapshot,
          PrefetchHooks Function()
        > {
  $$OptimizationSnapshotsTableTableManager(
    _$AppDatabase db,
    $OptimizationSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OptimizationSnapshotsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$OptimizationSnapshotsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OptimizationSnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<bool> stale = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OptimizationSnapshotsCompanion(
                cacheKey: cacheKey,
                userId: userId,
                sessionId: sessionId,
                payload: payload,
                stale: stale,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String userId,
                required String sessionId,
                required String payload,
                Value<bool> stale = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => OptimizationSnapshotsCompanion.insert(
                cacheKey: cacheKey,
                userId: userId,
                sessionId: sessionId,
                payload: payload,
                stale: stale,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OptimizationSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OptimizationSnapshotsTable,
      OptimizationSnapshot,
      $$OptimizationSnapshotsTableFilterComposer,
      $$OptimizationSnapshotsTableOrderingComposer,
      $$OptimizationSnapshotsTableAnnotationComposer,
      $$OptimizationSnapshotsTableCreateCompanionBuilder,
      $$OptimizationSnapshotsTableUpdateCompanionBuilder,
      (
        OptimizationSnapshot,
        BaseReferences<
          _$AppDatabase,
          $OptimizationSnapshotsTable,
          OptimizationSnapshot
        >,
      ),
      OptimizationSnapshot,
      PrefetchHooks Function()
    >;
typedef $$SyncEventsTableCreateCompanionBuilder =
    SyncEventsCompanion Function({
      Value<int> id,
      required DateTime occurredAt,
      required String source,
      required String outcome,
      Value<int> processed,
      Value<int> failed,
      Value<String?> details,
    });
typedef $$SyncEventsTableUpdateCompanionBuilder =
    SyncEventsCompanion Function({
      Value<int> id,
      Value<DateTime> occurredAt,
      Value<String> source,
      Value<String> outcome,
      Value<int> processed,
      Value<int> failed,
      Value<String?> details,
    });

class $$SyncEventsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncEventsTable> {
  $$SyncEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get processed => $composableBuilder(
    column: $table.processed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failed => $composableBuilder(
    column: $table.failed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncEventsTable> {
  $$SyncEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get processed => $composableBuilder(
    column: $table.processed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failed => $composableBuilder(
    column: $table.failed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncEventsTable> {
  $$SyncEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<int> get processed =>
      $composableBuilder(column: $table.processed, builder: (column) => column);

  GeneratedColumn<int> get failed =>
      $composableBuilder(column: $table.failed, builder: (column) => column);

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);
}

class $$SyncEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncEventsTable,
          SyncEvent,
          $$SyncEventsTableFilterComposer,
          $$SyncEventsTableOrderingComposer,
          $$SyncEventsTableAnnotationComposer,
          $$SyncEventsTableCreateCompanionBuilder,
          $$SyncEventsTableUpdateCompanionBuilder,
          (
            SyncEvent,
            BaseReferences<_$AppDatabase, $SyncEventsTable, SyncEvent>,
          ),
          SyncEvent,
          PrefetchHooks Function()
        > {
  $$SyncEventsTableTableManager(_$AppDatabase db, $SyncEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<int> processed = const Value.absent(),
                Value<int> failed = const Value.absent(),
                Value<String?> details = const Value.absent(),
              }) => SyncEventsCompanion(
                id: id,
                occurredAt: occurredAt,
                source: source,
                outcome: outcome,
                processed: processed,
                failed: failed,
                details: details,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime occurredAt,
                required String source,
                required String outcome,
                Value<int> processed = const Value.absent(),
                Value<int> failed = const Value.absent(),
                Value<String?> details = const Value.absent(),
              }) => SyncEventsCompanion.insert(
                id: id,
                occurredAt: occurredAt,
                source: source,
                outcome: outcome,
                processed: processed,
                failed: failed,
                details: details,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncEventsTable,
      SyncEvent,
      $$SyncEventsTableFilterComposer,
      $$SyncEventsTableOrderingComposer,
      $$SyncEventsTableAnnotationComposer,
      $$SyncEventsTableCreateCompanionBuilder,
      $$SyncEventsTableUpdateCompanionBuilder,
      (SyncEvent, BaseReferences<_$AppDatabase, $SyncEventsTable, SyncEvent>),
      SyncEvent,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedResourcesTableTableManager get cachedResources =>
      $$CachedResourcesTableTableManager(_db, _db.cachedResources);
  $$LocalResumesTableTableManager get localResumes =>
      $$LocalResumesTableTableManager(_db, _db.localResumes);
  $$MutationOutboxTableTableManager get mutationOutbox =>
      $$MutationOutboxTableTableManager(_db, _db.mutationOutbox);
  $$OptimizationSnapshotsTableTableManager get optimizationSnapshots =>
      $$OptimizationSnapshotsTableTableManager(_db, _db.optimizationSnapshots);
  $$SyncEventsTableTableManager get syncEvents =>
      $$SyncEventsTableTableManager(_db, _db.syncEvents);
}
