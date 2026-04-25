import '../../data/models/administrator.dart';

class AdminAuthResult {
  final String token;
  final Administrator admin;

  const AdminAuthResult({required this.token, required this.admin});
}

class AdminAuthException implements Exception {
  final String message;
  final AdminAuthFailure failure;

  const AdminAuthException(this.failure, this.message);

  @override
  String toString() => 'AdminAuthException($failure): $message';
}

enum AdminAuthFailure {
  invalidCredentials,
  network,
  unknown,
}

abstract class AdminAuthRepository {
  /// Authenticate with username + password. Throws [AdminAuthException] on failure.
  Future<AdminAuthResult> login({
    required String username,
    required String password,
  });

  /// Returns the currently authenticated admin and token if a session exists,
  /// or null when no session is stored.
  Future<AdminAuthResult?> restoreSession();

  /// Clears any stored admin session.
  Future<void> logout();
}
