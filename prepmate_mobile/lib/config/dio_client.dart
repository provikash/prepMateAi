import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final dioProvider = Provider<Dio>((ref) {
  // Use 10.0.2.2 for Android Emulator, or your exact local IP for physical devices.
  // Ensure the port (e.g., :8000) matches your Django server.
  const String baseUrl = 'http://10.157.211.1:8000/api/';

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.path.contains("auth/")) {
          return handler.next(options);
        }

        final token = await ref
            .read(secureStorageProvider)
            .read(key: 'access_token');

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        if (kDebugMode) {
          debugPrint('→ REQUEST [${options.method}] ${options.uri}');
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
            '← RESPONSE [${response.statusCode}] ${response.requestOptions.uri}',
          );
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

  return dio;
});
