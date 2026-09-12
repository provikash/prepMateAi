import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure, encrypted key-value store for JWT access + refresh tokens.
///
/// Uses AES-256 encryption on Android (KeyStore-backed) and the iOS
/// Keychain on Apple platforms. Tokens are **never** written to logs.
class TokenService {
  static final _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // ─── Write ──────────────────────────────────────────────────────────────

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Saves access token and, only when [refreshToken] is non-null/non-empty,
  /// also updates the refresh token.  Refresh token is **never** overwritten
  /// with a blank value.
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await saveRefreshToken(refreshToken);
    }
  }

  // ─── Read ───────────────────────────────────────────────────────────────

  static Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  // ─── Aliases kept for backward-compatibility ────────────────────────────

  /// Alias for [saveAccessToken].
  static Future<void> saveToken(String token) => saveAccessToken(token);

  /// Alias for [getAccessToken].
  static Future<String?> getToken() => getAccessToken();

  // ─── Delete ─────────────────────────────────────────────────────────────

  /// Clears both tokens (called on logout / refresh failure).
  static Future<void> deleteToken() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  static Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }
}