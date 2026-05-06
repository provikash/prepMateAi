// lib/config/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/services/auth_token_manager.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Main application [Dio] instance.
///
/// Interceptor chain (in order):
///   1. [onRequest]  — attach Bearer token (proactive refresh if near expiry).
///   2. [onResponse] — debug logging only.
///   3. [onError]    — on 401, attempt one token refresh then retry;
///                     if that fails, trigger forced logout.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(

      // ⚠️  Change this to your environment-specific URL.
      baseUrl: 'http://10.213.59.93:8000/api/v1/',

      // Change this based on your environment
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // ─── Request interceptor ─────────────────────────────────────────────────
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip token injection for auth & explicitly-skipped endpoints.
        if (options.extra['skipAuth'] == true) {
          _logRequest(options);
          return handler.next(options);
        }

        // Attaches a valid Bearer token; proactively refreshes if near expiry.
        final manager = ref.read(authTokenManagerProvider);
        await manager.maybeAttachOrRefresh(options);

        _logRequest(options);
        handler.next(options);
      },

      // ─── Response interceptor ───────────────────────────────────────────
      onResponse: (response, handler) {
        _logResponse(response);
        handler.next(response);
      },

      // ─── Error interceptor ──────────────────────────────────────────────
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          // Attempt one silent token refresh + request retry.
          try {
            final manager = ref.read(authTokenManagerProvider);
            final retried = await manager.retryWithFreshToken(
              dio,
              error.requestOptions,
            );
            if (retried != null) {
              // Successfully retried — resolve the original error with the
              // fresh response so the caller never sees a 401.
              return handler.resolve(retried);
            }
          } on DioException catch (retryError) {
            // retryWithFreshToken already called handleUnauthorized() if the
            // retry itself returned 401 — pass through with the retry error.
            return handler.next(retryError);
          } catch (_) {
            // Unexpected error — fall through and surface the original 401.
          }
        }

        _logError(error);
        handler.next(error);
      },
    ),
  );

  return dio;
});

// ─── Private logging helpers ─────────────────────────────────────────────────
// Tokens are intentionally excluded from all log output.

void _logRequest(RequestOptions options) {
  if (!kDebugMode) return;
  debugPrint('→ [${options.method}] ${options.uri}');
  if (options.data != null) {
    debugPrint('  Body: ${_scrubSensitiveFields(options.data)}');
  }
}

void _logResponse(Response response) {
  if (!kDebugMode) return;
  debugPrint('← [${response.statusCode}] ${response.requestOptions.uri}');
}

void _logError(DioException error) {
  if (!kDebugMode) return;
  debugPrint(
    '✗ [${error.response?.statusCode}] ${error.requestOptions.uri} — ${error.message}',
  );
}

/// Removes known sensitive keys so tokens never appear in logs.
dynamic _scrubSensitiveFields(dynamic data) {
  if (data is Map<String, dynamic>) {
    const sensitive = {'password', 'refresh', 'access', 'token', 'id_token'};
    return data.map(
      (k, v) => MapEntry(k, sensitive.contains(k) ? '***' : v),
    );
  }
  return data;
}
