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
          ? 'http://192.168.89.108:8000/api/' // local dev (replace with your IP)
          : 'https://api.prepmate.in/api/', // production URL
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // ─── Interceptors
  //
  // ────────────────────────────────────────


  dio.interceptors.add(
    InterceptorsWrapper(

      onRequest: (options, handler) async {

        final token = await ref
            .read(secureStorageProvider)
            .read(key: 'auth_token');

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        if (kDebugMode) {
          debugPrint('→ REQUEST [${options.method}] ${options.uri}');
          if (options.data != null) {
            debugPrint("  Body: ${options.data}");
          }
        }

        handler.next(options);
      },

      onResponse: (response, handler) {

        if (kDebugMode) {
          debugPrint(
            '← RESPONSE [${response.statusCode}] ${response.requestOptions.uri}',
          );

          if (response.data != null) {
            debugPrint("  Data: ${response.data}");
          }
        }

        handler.next(response);
      },

      onError: (DioException e, handler) {

        if (kDebugMode) {
          debugPrint(
            '✗ ERROR [${e.response?.statusCode}] ${e.requestOptions.uri}',
          );
          debugPrint('Message: ${e.message}');
        }

        handler.next(e);
      },
    ),
  );

  // Optional: add pretty logger in debug (requires dio_logger package or custom)
  // if (kDebugMode) dio.interceptors.add(PrettyDioLogger(...));

  return dio;
});
