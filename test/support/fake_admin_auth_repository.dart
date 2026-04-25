import 'package:lib_42_flutter/features/admin_catalog/data/models/administrator.dart';
import 'package:lib_42_flutter/features/admin_catalog/domain/repositories/admin_auth_repository.dart';

/// Test fake for [AdminAuthRepository]. Callers control the outcome of each
/// method via the public fields — no HTTP or secure-storage required.
class FakeAdminAuthRepository implements AdminAuthRepository {
  AdminAuthResult? loginResult;
  AdminAuthException? loginError;
  AdminAuthResult? restoredSession;
  int loginCalls = 0;
  int logoutCalls = 0;
  int restoreCalls = 0;

  @override
  Future<AdminAuthResult> login({
    required String username,
    required String password,
  }) async {
    loginCalls++;
    if (loginError != null) throw loginError!;
    if (loginResult != null) return loginResult!;
    throw const AdminAuthException(
      AdminAuthFailure.unknown,
      'FakeAdminAuthRepository: loginResult or loginError not set',
    );
  }

  @override
  Future<AdminAuthResult?> restoreSession() async {
    restoreCalls++;
    return restoredSession;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

Administrator makeAdmin({
  String id = 'admin-1',
  String username = 'admin',
  String email = 'admin@42lib.kr',
  String fullName = '관리자',
  AdminRole role = AdminRole.admin,
}) {
  return Administrator(
    id: id,
    username: username,
    email: email,
    fullName: fullName,
    role: role,
  );
}
