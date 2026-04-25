import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../services/storage/secure_storage_service.dart';
import '../../domain/repositories/admin_auth_repository.dart';
import '../models/administrator.dart';

/// HTTP-backed implementation of [AdminAuthRepository].
///
/// Targets the backend mounted at `<baseUrl>/v1/admin/*`. Uses its own Dio
/// instance so that student-flow interceptors (which inject the student JWT)
/// don't leak admin credentials.
class AdminAuthRepositoryImpl implements AdminAuthRepository {
  AdminAuthRepositoryImpl({
    required String baseUrl,
    SecureStorageService? storage,
    Dio? httpClient,
  })  : _storage = storage ?? SecureStorageService(),
        _dio = httpClient ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Content-Type': 'application/json'},
                // Accept 4xx so we can translate to domain errors ourselves.
                validateStatus: (status) => status != null && status < 500,
              ),
            );

  final SecureStorageService _storage;
  final Dio _dio;

  @override
  Future<AdminAuthResult> login({
    required String username,
    required String password,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        '/v1/admin/login',
        data: {'username': username, 'password': password},
      );
    } on DioException catch (e) {
      throw AdminAuthException(
        AdminAuthFailure.network,
        e.message ?? '네트워크 오류가 발생했습니다.',
      );
    }

    if (response.statusCode == 401) {
      throw const AdminAuthException(
        AdminAuthFailure.invalidCredentials,
        '사용자명 또는 비밀번호가 올바르지 않습니다.',
      );
    }

    if (response.statusCode != 200 || response.data is! Map) {
      throw AdminAuthException(
        AdminAuthFailure.unknown,
        '예상치 못한 응답 (${response.statusCode}).',
      );
    }

    final body = response.data as Map<String, dynamic>;
    final token = body['token'] as String?;
    final adminJson = body['admin'] as Map<String, dynamic>?;
    if (token == null || adminJson == null) {
      throw const AdminAuthException(
        AdminAuthFailure.unknown,
        '응답 형식이 유효하지 않습니다.',
      );
    }

    final admin = Administrator.fromJson(adminJson);
    await _storage.writeAdminToken(token);
    await _storage.writeAdminProfile(jsonEncode(admin.toJson()));

    return AdminAuthResult(token: token, admin: admin);
  }

  @override
  Future<AdminAuthResult?> restoreSession() async {
    final token = await _storage.readAdminToken();
    final profileJson = await _storage.readAdminProfile();
    if (token == null || token.isEmpty || profileJson == null) return null;
    try {
      final admin = Administrator.fromJson(
        jsonDecode(profileJson) as Map<String, dynamic>,
      );
      return AdminAuthResult(token: token, admin: admin);
    } catch (_) {
      // Corrupted profile — clear and force re-login.
      await logout();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await _storage.deleteAdminToken();
    await _storage.deleteAdminProfile();
  }
}
