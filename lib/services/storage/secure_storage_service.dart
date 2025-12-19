import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 안전한 저장소 서비스 - 42 OAuth 토큰 관리 지원
class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _key42Token = '42_oauth_token';
  static const String _keyJwtToken = 'jwt_token';

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // Legacy methods (keep for backward compatibility)
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _key42Token);
    await _storage.delete(key: _keyJwtToken);
  }

  // New methods for 42 OAuth and JWT tokens (T121)

  /// Write JWT token (from backend after OAuth)
  Future<void> writeToken(String token) async {
    await _storage.write(key: _keyJwtToken, value: token);
  }

  /// Read JWT token
  Future<String?> readToken() async {
    return await _storage.read(key: _keyJwtToken);
  }

  /// Delete JWT token
  Future<void> deleteToken() async {
    await _storage.delete(key: _keyJwtToken);
  }

  /// Write refresh token
  Future<void> writeRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  /// Read refresh token
  Future<String?> readRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _keyRefreshToken);
  }

  /// Write 42 OAuth token (if needed for direct 42 API calls)
  Future<void> write42Token(String token) async {
    await _storage.write(key: _key42Token, value: token);
  }

  /// Read 42 OAuth token
  Future<String?> read42Token() async {
    return await _storage.read(key: _key42Token);
  }

  /// Check if authenticated (has JWT token)
  Future<bool> isAuthenticated() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored tokens
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
