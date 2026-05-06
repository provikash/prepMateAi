import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage.dart';
import '../../features/auth/presentation/viewmodel/auth_viewmodel.dart';

// ─── Provider ───────────────────────────────────────────────────────────────

final authTokenManagerProvider = Provider<AuthTokenManager>((ref) {
  return AuthTokenManager(ref);
});

// ─── AuthTokenManager ────────────────────────────────────────────────────────

/// Central JWT lifecycle controller.
///
/// Responsibilities
/// ────────────────
/// • Secure read/write of access + refresh tokens via [TokenService].
/// • Proactive (pre-emptive) refresh when the access token is within
///   [_refreshWindow] of expiry — so the user never sees a 401.
/// • Reactive refresh on 401: retries the original request exactly once
///   with a fresh token.
/// • If refresh itself fails → clears storage, fires [logoutStream] so the
///   UI can navigate to the login screen without an explicit GoRouter import.
/// • Tokens are **never** written to logs in release mode.
class AuthTokenManager {
  AuthTokenManager(this._ref);

  // ⚠️  Configure your backend URL here (must match dio_client.dart):
  // For Android Emulator (default): http://10.0.2.2:8000/api/v1/
  // For Physical Device: http://<YOUR_MACHINE_IP>:8000/api/v1/
  static const String _baseUrl = 'http://10.24.117.1:8000/api/v1/';
  static const Duration _refreshWindow = Duration(minutes: 2);

  final Ref _ref;

  // Separate Dio instance used only for the refresh call so we don't
  // accidentally trigger the main interceptor recursively.
  final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // ── Public logout stream ─────────────────────────────────────────────────

  /// Broadcast stream that emits once whenever a forced logout occurs
  /// (i.e., the refresh token is expired / invalid).  The UI listens to
  /// this and navigates to the login screen.
  static final StreamController<void> _logoutController =
      StreamController<void>.broadcast();

  static Stream<void> get logoutStream => _logoutController.stream;

  // ─── Token accessors ────────────────────────────────────────────────────

  Future<String?> getAccessToken() => TokenService.getAccessToken();
  Future<String?> getRefreshToken() => TokenService.getRefreshToken();

  /// Saves tokens.  Refresh token is only updated when non-null/non-empty
  /// so an access-only refresh response never wipes the refresh token.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) {
    return TokenService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> saveAccessToken(String token) =>
      TokenService.saveAccessToken(token);

  Future<void> clearTokens() => TokenService.deleteToken();

  // ─── Auth-endpoint detection ─────────────────────────────────────────────

  bool _isAuthEndpoint(RequestOptions options) {
    final path = options.path;
    return path.contains('auth/login') ||
        path.contains('auth/register') ||
        path.contains('auth/refresh') ||
        path.contains('auth/google') ||
        path.contains('auth/forgot-password') ||
        path.contains('verify-otp') ||
        path.contains('verify-login-otp');
  }

  bool _shouldBypassAuth(RequestOptions options) {
    return options.extra['skipAuth'] == true || _isAuthEndpoint(options);
  }

  // ─── Proactive / on-demand token validation ───────────────────────────────

  /// Returns a valid access token.
  ///
  /// • If the stored token is present and not expiring soon → returns it.
  /// • If it is expiring soon (within [_refreshWindow]) → refreshes first.
  /// • [forceRefresh] skips the expiry check and always calls the refresh
  ///   endpoint (used by the 401 retry path).
  Future<String?> getValidAccessToken({bool forceRefresh = false}) async {
    final accessToken = await getAccessToken();

    if (!forceRefresh && accessToken != null && accessToken.isNotEmpty) {
      if (!_isExpiringSoon(accessToken)) {
        return accessToken;
      }
      _log('Access token expiring soon — refreshing proactively');
    }

    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      // No refresh token → return whatever we have (may be null).
      return accessToken;
    }

    return refreshAccessToken(refreshToken: refreshToken);
  }

  // ─── JWT expiry helpers ───────────────────────────────────────────────────

  bool _isExpiringSoon(String token) {
    final expiry = _getTokenExpiry(token);
    if (expiry == null) return false;
    return expiry.isBefore(DateTime.now().add(_refreshWindow));
  }

  DateTime? _getTokenExpiry(String token) {
    try {
      final segments = token.split('.');
      if (segments.length < 2) return null;
      final normalized = base64Url.normalize(segments[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final data = json.decode(payload);
      if (data is Map<String, dynamic>) {
        final exp = data['exp'];
        if (exp is int) {
          return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true)
              .toLocal();
        }
        if (exp is String) {
          final parsed = int.tryParse(exp);
          if (parsed != null) {
            return DateTime.fromMillisecondsSinceEpoch(
              parsed * 1000,
              isUtc: true,
            ).toLocal();
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  // ─── Token refresh ────────────────────────────────────────────────────────

  /// Calls `/api/v1/auth/refresh/` and persists the new access token.
  ///
  /// Returns the new access token on success, or `null` on failure.
  /// Does **not** call [handleUnauthorized] itself — the caller decides.
  Future<String?> refreshAccessToken({String? refreshToken}) async {
    final token = refreshToken ?? await getRefreshToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _refreshDio.post(
        'auth/refresh/',
        data: {'refresh': token},
        options: Options(extra: {'skipAuth': true}),
      );

      final payload = response.data;
      if (payload is! Map<String, dynamic>) return null;

      final tokens = payload['tokens'];
      final newAccess = _extractAccessToken(payload, tokens);
      final newRefresh = _extractRefreshToken(payload, tokens);

      if (newAccess == null || newAccess.isEmpty) return null;

      await TokenService.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh, // null is safe — won't overwrite existing
      );

      _log('Token refreshed successfully');
      return newAccess;
    } on DioException catch (error) {
      // Only log the status code in debug mode — never the token value.
      _log('Token refresh failed: HTTP ${error.response?.statusCode}');
      return null;
    } catch (error) {
      _log('Token refresh failed: $error');
      return null;
    }
  }

  // ─── Forced logout ────────────────────────────────────────────────────────

  /// Clears all stored tokens, notifies the Riverpod auth state, and
  /// emits on [logoutStream] so any UI listener can navigate to login.
  Future<void> handleUnauthorized() async {
    await clearTokens();
    // Notify Riverpod state.
    _ref.read(authViewModelProvider.notifier).logout();
    // Also notify raw stream listeners (e.g., navigation outside widget tree).
    _logoutController.add(null);
  }

  // ─── Interceptor helpers ─────────────────────────────────────────────────

  /// Called by the Dio interceptor's `onRequest`.
  ///
  /// Attaches a valid Bearer token to [options.headers].
  /// Returns `true` when a token was attached, `false` when the endpoint
  /// is an auth route or no token exists.
  Future<bool> maybeAttachOrRefresh(RequestOptions options) async {
    if (_shouldBypassAuth(options)) return false;

    final token = await getValidAccessToken();
    if (token == null || token.isEmpty) return false;

    options.headers['Authorization'] = 'Bearer $token';
    return true;
  }

  /// Called by the Dio interceptor's `onError` when a 401 is received.
  ///
  /// Retries the original request **once** with a force-refreshed token.
  /// Marks the retry with `auth_retry: true` so we never loop.
  /// Returns `null` when the retry is skipped or the refresh fails.
  Future<Response<dynamic>?> retryWithFreshToken(
    Dio dio,
    RequestOptions requestOptions,
  ) async {
    // Guard: skip auth routes and second-attempt retries.
    if (_shouldBypassAuth(requestOptions) ||
        requestOptions.extra['auth_retry'] == true) {
      return null;
    }

    final freshToken = await getValidAccessToken(forceRefresh: true);
    if (freshToken == null || freshToken.isEmpty) {
      await handleUnauthorized();
      return null;
    }

    final retryOptions = Options(
      method: requestOptions.method,
      headers: Map<String, dynamic>.from(requestOptions.headers)
        ..['Authorization'] = 'Bearer $freshToken',
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      followRedirects: requestOptions.followRedirects,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
      validateStatus: requestOptions.validateStatus,
      extra: {
        ...requestOptions.extra,
        'auth_retry': true, // Prevent infinite retry loop
        'skipAuth': true,   // Bypass the onRequest interceptor
      },
    );

    try {
      _log('Retrying request after token refresh: ${requestOptions.path}');
      final response = await dio.request<dynamic>(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: retryOptions,
        cancelToken: requestOptions.cancelToken,
        onReceiveProgress: requestOptions.onReceiveProgress,
        onSendProgress: requestOptions.onSendProgress,
      );
      return response;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        // Retry itself got a 401 → refresh token is expired.
        await handleUnauthorized();
      }
      rethrow;
    }
  }

  // ─── Token extraction helpers ────────────────────────────────────────────

  String? _extractAccessToken(
    Map<String, dynamic> payload,
    dynamic tokens,
  ) {
    if (tokens is Map<String, dynamic>) {
      final access = tokens['access'] ?? tokens['access_token'];
      if (access != null) return access.toString();
    }
    final fallback = payload['access'] ?? payload['access_token'];
    return fallback?.toString();
  }

  String? _extractRefreshToken(
    Map<String, dynamic> payload,
    dynamic tokens,
  ) {
    if (tokens is Map<String, dynamic>) {
      final refresh = tokens['refresh'] ?? tokens['refresh_token'];
      if (refresh != null) return refresh.toString();
    }
    final fallback = payload['refresh'] ?? payload['refresh_token'];
    return fallback?.toString();
  }

  // ─── Internal logging ─────────────────────────────────────────────────────

  /// Debug-only log helper — tokens are never included.
  void _log(String message) {
    if (kDebugMode) debugPrint('[AuthTokenManager] $message');
  }
}
