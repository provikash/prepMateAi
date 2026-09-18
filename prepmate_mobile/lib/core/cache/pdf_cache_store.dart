import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PdfCacheRecord {
  const PdfCacheRecord({
    required this.path,
    required this.etag,
    required this.cachedAt,
    required this.size,
  });

  final String path;
  final String etag;
  final DateTime cachedAt;
  final int size;

  Map<String, dynamic> toJson() => {
    'path': path,
    'etag': etag,
    'cached_at': cachedAt.toUtc().toIso8601String(),
    'size': size,
  };

  static PdfCacheRecord? tryParse(String value) {
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      return PdfCacheRecord(
        path: json['path'] as String,
        etag: json['etag'] as String? ?? '',
        cachedAt: DateTime.parse(json['cached_at'] as String),
        size: json['size'] as int,
      );
    } catch (_) {
      return null;
    }
  }
}

class PdfCacheStore {
  static const _metadataPrefix = 'prepmate_pdf_v1_';
  static const _freshFor = Duration(minutes: 2);
  static const _maxFiles = 8;
  static const _maxBytes = 60 * 1024 * 1024;

  String _key(String userId, String resumeId) => '$userId:$resumeId';

  Future<PdfCacheRecord?> metadata(String userId, String resumeId) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = '$_metadataPrefix${_key(userId, resumeId)}';
    final encoded = prefs.getString(storageKey);
    final record = encoded == null ? null : PdfCacheRecord.tryParse(encoded);
    if (record == null || !await File(record.path).exists()) {
      await prefs.remove(storageKey);
      return null;
    }
    return record;
  }

  bool isFresh(PdfCacheRecord record) =>
      DateTime.now().difference(record.cachedAt) < _freshFor;

  Future<Uint8List?> read(PdfCacheRecord record) async {
    try {
      final bytes = await File(record.path).readAsBytes();
      if (bytes.isEmpty || bytes.length != record.size) {
        await File(record.path).delete();
        return null;
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> write({
    required String userId,
    required String resumeId,
    required String etag,
    required Uint8List bytes,
  }) async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}pdf_cache_v1',
    );
    await directory.create(recursive: true);
    final safeUser = _safe(userId);
    final safeResume = _safe(resumeId);
    final file = File(
      '${directory.path}${Platform.pathSeparator}${safeUser}_$safeResume.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);
    final record = PdfCacheRecord(
      path: file.path,
      etag: etag,
      cachedAt: DateTime.now(),
      size: bytes.length,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_metadataPrefix${_key(userId, resumeId)}',
      jsonEncode(record.toJson()),
    );
    await _evict(prefs);
  }

  Future<void> remove(String userId, String resumeId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_metadataPrefix${_key(userId, resumeId)}';
    final record = PdfCacheRecord.tryParse(prefs.getString(key) ?? '');
    if (record != null) {
      try {
        await File(record.path).delete();
      } catch (_) {}
    }
    await prefs.remove(key);
  }

  Future<void> removeForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '$_metadataPrefix$userId:';
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith(prefix))
        .toList();
    for (final key in keys) {
      final record = PdfCacheRecord.tryParse(prefs.getString(key) ?? '');
      if (record != null) {
        try {
          await File(record.path).delete();
        } catch (_) {}
      }
      await prefs.remove(key);
    }
  }

  Future<void> _evict(SharedPreferences prefs) async {
    final records = <MapEntry<String, PdfCacheRecord>>[];
    for (final key in prefs.getKeys().where(
      (key) => key.startsWith(_metadataPrefix),
    )) {
      final record = PdfCacheRecord.tryParse(prefs.getString(key) ?? '');
      if (record != null) records.add(MapEntry(key, record));
    }
    records.sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    var total = records.fold<int>(0, (sum, item) => sum + item.value.size);
    while (records.length > _maxFiles || total > _maxBytes) {
      final oldest = records.removeAt(0);
      total -= oldest.value.size;
      try {
        await File(oldest.value.path).delete();
      } catch (_) {}
      await prefs.remove(oldest.key);
    }
  }

  String _safe(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}

final pdfCacheStoreProvider = Provider<PdfCacheStore>((ref) => PdfCacheStore());
