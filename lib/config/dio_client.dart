import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/request_interceptors.dart';
import '../core/services/auth_token_manager.dart';
import 'api_config.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// The one application HTTP client. Widgets must consume repositories or
/// providers rather than reading this provider directly.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 180),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(RequestTelemetryInterceptor());
  dio.interceptors.add(PublicConditionalCacheInterceptor());
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.extra['skipAuth'] == true) {
          return handler.next(options);
        }
        await ref.read(authTokenManagerProvider).maybeAttachOrRefresh(options);
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          try {
            final retried = await ref
                .read(authTokenManagerProvider)
                .retryWithFreshToken(dio, error.requestOptions);
            if (retried != null) return handler.resolve(retried);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          } catch (_) {
            // Preserve the original 401 for the caller.
          }
        }
        handler.next(error);
      },
    ),
  );
  // Added after authentication so the key includes an in-memory account
  // fingerprint. The authorization value is never persisted or logged.
  dio.interceptors.add(SingleFlightInterceptor());

  ref.onDispose(() => dio.close(force: true));
  return dio;
});
