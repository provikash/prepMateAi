import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static final _storage = const FlutterSecureStorage();

  /// SAVE TOKEN
  static Future<void> saveToken(String token) async {
    await _storage.write(key: "access_token", value: token);
  }

  /// GET TOKEN
  static Future<String?> getToken() async {
    return await _storage.read(key: "access_token");
  }

  /// DELETE TOKEN (logout)
  static Future<void> deleteToken() async {
    await _storage.delete(key: "access_token");
  }
}