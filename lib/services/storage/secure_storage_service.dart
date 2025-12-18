import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 안전한 저장소 서비스
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _keyAccessToken = 'access_token';
  static const String _keyUserId = 'user_id';

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyUserId);
  }
}
