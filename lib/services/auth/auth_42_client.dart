import 'dart:convert';
import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import '../../models/student.dart';

/// Service for handling 42 OAuth authentication
class Auth42Client {
  final Dio _dio;
  final SecureStorageService _secureStorage;
  final String baseUrl;
  final String clientId;
  final String redirectUri;

  Auth42Client({
    required Dio dio,
    required SecureStorageService secureStorage,
    required this.baseUrl,
    required this.clientId,
    required this.redirectUri,
  })  : _dio = dio,
        _secureStorage = secureStorage;

  /// Generate 42 OAuth authorization URL
  String getAuthorizationUrl({String? state}) {
    final params = {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'public',
      if (state != null) 'state': state,
    };

    final queryString = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$baseUrl/oauth/authorize?$queryString';
  }

  /// Exchange authorization code for access token
  /// Returns JWT token from backend
  Future<Map<String, dynamic>> exchangeCodeForToken(String code) async {
    try {
      final response = await _dio.get(
        '/auth/42/callback',
        queryParameters: {'code': code},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Store JWT token securely
        if (data.containsKey('token')) {
          await _secureStorage.writeToken(data['token'] as String);
        }

        // Store refresh token if provided
        if (data.containsKey('refreshToken')) {
          await _secureStorage
              .writeRefreshToken(data['refreshToken'] as String);
        }

        return data;
      } else {
        throw Exception('Failed to exchange code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('42 OAuth 인증에 실패했습니다');
      } else if (e.response?.statusCode == 400) {
        throw Exception('잘못된 인증 코드입니다');
      }
      throw Exception('OAuth 인증 중 오류가 발생했습니다: ${e.message}');
    } catch (e) {
      throw Exception('OAuth 인증 중 예상치 못한 오류가 발생했습니다');
    }
  }

  /// Get current authenticated student profile
  Future<Student> getCurrentStudent() async {
    try {
      final token = await _secureStorage.readToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다');
      }

      final response = await _dio.get(
        '/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return Student.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('프로필 조회 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _secureStorage.deleteToken();
        throw Exception('인증이 만료되었습니다. 다시 로그인해주세요.');
      }
      throw Exception('프로필 조회 중 오류가 발생했습니다: ${e.message}');
    }
  }

  /// Refresh JWT token using refresh token
  Future<String> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.readRefreshToken();
      if (refreshToken == null) {
        throw Exception('리프레시 토큰이 없습니다');
      }

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newToken = data['token'] as String;

        await _secureStorage.writeToken(newToken);

        if (data.containsKey('refreshToken')) {
          await _secureStorage
              .writeRefreshToken(data['refreshToken'] as String);
        }

        return newToken;
      } else {
        throw Exception('토큰 갱신 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _secureStorage.deleteToken();
        await _secureStorage.deleteRefreshToken();
        throw Exception('리프레시 토큰이 만료되었습니다. 다시 로그인해주세요.');
      }
      throw Exception('토큰 갱신 중 오류가 발생했습니다: ${e.message}');
    }
  }

  /// Logout - clear stored tokens
  Future<void> logout() async {
    await _secureStorage.deleteToken();
    await _secureStorage.deleteRefreshToken();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.readToken();
    return token != null && token.isNotEmpty;
  }

  /// Get stored JWT token
  Future<String?> getToken() async {
    return await _secureStorage.readToken();
  }
}
