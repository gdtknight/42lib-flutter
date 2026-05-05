import 'package:dio/dio.dart';
import 'package:lib_42_flutter/models/student.dart';
import 'package:lib_42_flutter/services/auth/auth_42_client.dart';
import 'package:lib_42_flutter/services/storage/secure_storage_service.dart';

import 'fake_secure_storage_service.dart';

/// Manual fake of [Auth42Client] for AuthBloc tests. The real constructor
/// requires Dio + SecureStorageService — we satisfy them with stubs since
/// every method on this fake is overridden.
class FakeAuth42Client extends Auth42Client {
  FakeAuth42Client()
      : super(
          dio: Dio(),
          secureStorage: FakeSecureStorageService(),
          baseUrl: 'https://test',
          clientId: 'test-client',
          redirectUri: 'http://localhost/cb',
        );

  // Configurable behavior
  bool isAuth = false;
  String? token;
  Student? currentStudent;
  Object? getCurrentStudentError;
  String authorizationUrl = 'https://test/oauth/authorize?client_id=test';
  Map<String, dynamic>? exchangeResult;
  Object? exchangeError;
  String? refreshResult;
  Object? refreshError;
  Object? logoutError;

  // Call counters
  int isAuthenticatedCalls = 0;
  int getCurrentStudentCalls = 0;
  int getTokenCalls = 0;
  int getAuthorizationUrlCalls = 0;
  int exchangeCalls = 0;
  int refreshCalls = 0;
  int logoutCalls = 0;
  String? lastExchangeCode;
  String? lastAuthorizationState;

  @override
  Future<bool> isAuthenticated() async {
    isAuthenticatedCalls++;
    return isAuth;
  }

  @override
  Future<String?> getToken() async {
    getTokenCalls++;
    return token;
  }

  @override
  Future<Student> getCurrentStudent() async {
    getCurrentStudentCalls++;
    if (getCurrentStudentError != null) {
      throw getCurrentStudentError!;
    }
    if (currentStudent == null) {
      throw Exception('FakeAuth42Client.currentStudent not set');
    }
    return currentStudent!;
  }

  @override
  String getAuthorizationUrl({String? state}) {
    getAuthorizationUrlCalls++;
    lastAuthorizationState = state;
    return authorizationUrl;
  }

  @override
  Future<Map<String, dynamic>> exchangeCodeForToken(String code) async {
    exchangeCalls++;
    lastExchangeCode = code;
    if (exchangeError != null) throw exchangeError!;
    return exchangeResult ?? {'token': 'jwt-default'};
  }

  @override
  Future<String> refreshToken() async {
    refreshCalls++;
    if (refreshError != null) throw refreshError!;
    return refreshResult ?? 'jwt-refreshed';
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutError != null) throw logoutError!;
  }
}

Student makeTestStudent({
  String id = 'stu-1',
  int fortytwoUserId = 12345,
  String username = 'yoshin',
  String email = 'yoshin@42.fr',
  String fullName = '테스트 학생',
}) {
  return Student(
    id: id,
    fortytwoUserId: fortytwoUserId,
    username: username,
    email: email,
    fullName: fullName,
    createdAt: DateTime(2024, 1, 1),
    lastLoginAt: DateTime(2024, 2, 1),
  );
}
