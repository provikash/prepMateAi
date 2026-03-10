// lib/config/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ────────────────────────────────────────────────
// Providers
// ────────────────────────────────────────────────

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      // Change this based on your environment
      baseUrl: kDebugMode
          ? 'http://192.168.1.100:8000/api/' // local dev (replace with your IP)
          : 'https://api.prepmate.in/api/', // production URL
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // ─── Interceptors ────────────────────────────────────────

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Attach Authorization header if token exists
        final token = await ref
            .read(secureStorageProvider)
            .read(key: 'auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Optional: pretty log in debug mode
        if (kDebugMode) {
          debugPrint('→ REQUEST [${options.method}] ${options.uri}');
          if (options.data != null) {
            debugPrint(
              '  Body: ${options.data.toString().substring(0, 200)}...',
            );
          }
        }

        return handler.next(options);
      },

      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
            '← RESPONSE [${response.statusCode}] ${response.requestOptions.uri}',
          );
          if (response.data != null) {
            debugPrint(
              '  Data: ${response.data.toString().substring(0, 200)}...',
            );
          }
        }
        return handler.next(response);
      },

      onError: (DioException e, handler) async {
        if (kDebugMode) {
          debugPrint(
            '✗ ERROR [${e.response?.statusCode}] ${e.requestOptions.uri}',
          );
          debugPrint('  Message: ${e.message}');
          if (e.response?.data != null) {
            debugPrint('  Response: ${e.response?.data}');
          }
        }

        // Handle common auth errors globally
        if (e.response?.statusCode == 401) {
          // Token expired/invalid → clear storage & redirect to login
          await ref.read(secureStorageProvider).delete(key: 'auth_token');
          // You can add global event bus or notifier here to trigger logout UI
          // For now, just let the screen handle it via state
        }

        // Optional: auto retry on certain errors (e.g., 503, timeout)
        // if (e.type == DioExceptionType.connectionTimeout && e.requestOptions.extra['retries'] != null) { ... }

        return handler.next(e);
      },
    ),
  );

  // Optional: add pretty logger in debug (requires dio_logger package or custom)
  // if (kDebugMode) dio.interceptors.add(PrettyDioLogger(...));

  return dio;
});
