import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/admin_catalog/domain/repositories/admin_auth_repository.dart';
import 'package:lib_42_flutter/features/admin_catalog/presentation/bloc/admin_auth_bloc.dart';
import 'package:lib_42_flutter/features/admin_catalog/presentation/bloc/admin_auth_event.dart';
import 'package:lib_42_flutter/features/admin_catalog/presentation/bloc/admin_auth_state.dart';

import '../../../../support/fake_admin_auth_repository.dart';

void main() {
  group('AdminAuthBloc (T083)', () {
    late FakeAdminAuthRepository repository;

    setUp(() {
      repository = FakeAdminAuthRepository();
    });

    blocTest<AdminAuthBloc, AdminAuthState>(
      'emits [Loading, Authenticated] on successful login',
      build: () {
        final admin = makeAdmin();
        repository.loginResult =
            AdminAuthResult(token: 'tok-abc', admin: admin);
        return AdminAuthBloc(repository: repository);
      },
      act: (bloc) => bloc.add(
        const AdminAuthRequested(username: 'admin', password: 'admin123'),
      ),
      expect: () => [
        isA<AdminAuthLoading>(),
        isA<AdminAuthenticated>()
            .having((s) => s.token, 'token', 'tok-abc')
            .having((s) => s.admin.username, 'admin.username', 'admin'),
      ],
      verify: (_) {
        expect(repository.loginCalls, 1);
      },
    );

    blocTest<AdminAuthBloc, AdminAuthState>(
      'emits [Loading, Failed] with invalid credentials',
      build: () {
        repository.loginError = const AdminAuthException(
          AdminAuthFailure.invalidCredentials,
          '사용자명 또는 비밀번호가 올바르지 않습니다.',
        );
        return AdminAuthBloc(repository: repository);
      },
      act: (bloc) => bloc.add(
        const AdminAuthRequested(username: 'admin', password: 'wrong'),
      ),
      expect: () => [
        isA<AdminAuthLoading>(),
        isA<AdminAuthFailed>()
            .having((s) => s.failure, 'failure',
                AdminAuthFailure.invalidCredentials),
      ],
    );

    blocTest<AdminAuthBloc, AdminAuthState>(
      'session restore: emits Authenticated when session exists',
      build: () {
        repository.restoredSession = AdminAuthResult(
          token: 'existing-token',
          admin: makeAdmin(username: 'persistent'),
        );
        return AdminAuthBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const AdminAuthSessionRestored()),
      expect: () => [
        isA<AdminAuthenticated>()
            .having((s) => s.admin.username, 'admin.username', 'persistent'),
      ],
    );

    blocTest<AdminAuthBloc, AdminAuthState>(
      'session restore: emits Unauthenticated when no session',
      build: () {
        repository.restoredSession = null;
        return AdminAuthBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const AdminAuthSessionRestored()),
      expect: () => [isA<AdminUnauthenticated>()],
    );

    blocTest<AdminAuthBloc, AdminAuthState>(
      'logout: clears session and emits Unauthenticated',
      build: () {
        repository.loginResult =
            AdminAuthResult(token: 'tok', admin: makeAdmin());
        return AdminAuthBloc(repository: repository);
      },
      seed: () => AdminAuthenticated(admin: makeAdmin(), token: 'tok'),
      act: (bloc) => bloc.add(const AdminAuthLogoutRequested()),
      expect: () => [isA<AdminUnauthenticated>()],
      verify: (_) {
        expect(repository.logoutCalls, 1);
      },
    );
  });
}
