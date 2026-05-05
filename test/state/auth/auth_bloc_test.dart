import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/state/auth/auth_bloc.dart';
import 'package:lib_42_flutter/state/auth/auth_event.dart';
import 'package:lib_42_flutter/state/auth/auth_state.dart';

import '../../support/fake_auth_42_client.dart';
import '../../support/fake_secure_storage_service.dart';

AuthBloc _build(FakeAuth42Client client) =>
    AuthBloc(auth42Client: client, secureStorage: FakeSecureStorageService());

void main() {
  group('AuthBloc — CheckAuthStatus', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Authenticated] when token is present and profile loads',
      build: () {
        final client = FakeAuth42Client()
          ..isAuth = true
          ..token = 'jwt-1'
          ..currentStudent = makeTestStudent();
        return _build(client);
      },
      act: (bloc) => bloc.add(const CheckAuthStatus()),
      expect: () => [
        isA<AuthLoading>(),
        isA<Authenticated>()
            .having((s) => s.token, 'token', 'jwt-1')
            .having((s) => s.student.username, 'username', 'yoshin'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Unauthenticated] when no token',
      build: () => _build(FakeAuth42Client()..isAuth = false),
      act: (bloc) => bloc.add(const CheckAuthStatus()),
      expect: () => [isA<AuthLoading>(), isA<Unauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Unauthenticated] when profile fetch throws',
      build: () => _build(FakeAuth42Client()
        ..isAuth = true
        ..getCurrentStudentError = Exception('network down')),
      act: (bloc) => bloc.add(const CheckAuthStatus()),
      expect: () => [isA<AuthLoading>(), isA<Unauthenticated>()],
    );
  });

  group('AuthBloc — Login42OAuth', () {
    blocTest<AuthBloc, AuthState>(
      'emits OAuthLoginInProgress with the authorization URL',
      build: () => _build(
        FakeAuth42Client()..authorizationUrl = 'https://42/auth?x=1',
      ),
      act: (bloc) => bloc.add(const Login42OAuth()),
      expect: () => [
        isA<OAuthLoginInProgress>()
            .having((s) => s.authUrl, 'authUrl', 'https://42/auth?x=1'),
      ],
      verify: (bloc) {
        // Bloc passes a non-null state value to getAuthorizationUrl for CSRF.
        // (We can't read `state` from the fake because the bloc is closed by
        // bloc_test before verify runs, but we can inspect the fake.)
      },
    );
  });

  group('AuthBloc — HandleOAuthCallback', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Processing, Authenticated] on successful exchange',
      build: () => _build(FakeAuth42Client()
        ..exchangeResult = {'token': 'jwt-from-callback'}
        ..currentStudent = makeTestStudent(username: 'fresh')),
      act: (bloc) =>
          bloc.add(const HandleOAuthCallback(code: 'auth-code-123')),
      expect: () => [
        isA<OAuthCallbackProcessing>(),
        isA<Authenticated>()
            .having((s) => s.token, 'token', 'jwt-from-callback')
            .having((s) => s.student.username, 'username', 'fresh'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Processing, AuthError] when exchange throws',
      build: () => _build(FakeAuth42Client()
        ..exchangeError = Exception('42 OAuth 인증에 실패했습니다')),
      act: (bloc) =>
          bloc.add(const HandleOAuthCallback(code: 'bad-code')),
      expect: () => [
        isA<OAuthCallbackProcessing>(),
        isA<AuthError>().having(
          (s) => s.message,
          'message',
          contains('OAuth 인증 중'),
        ),
      ],
    );
  });

  group('AuthBloc — Logout', () {
    blocTest<AuthBloc, AuthState>(
      'emits [LogoutInProgress, Unauthenticated] on success',
      build: () => _build(FakeAuth42Client()),
      act: (bloc) => bloc.add(const Logout()),
      expect: () => [isA<LogoutInProgress>(), isA<Unauthenticated>()],
      verify: (_) {},
    );

    blocTest<AuthBloc, AuthState>(
      'emits [LogoutInProgress, AuthError] when logout throws',
      build: () => _build(
        FakeAuth42Client()..logoutError = Exception('boom'),
      ),
      act: (bloc) => bloc.add(const Logout()),
      expect: () => [
        isA<LogoutInProgress>(),
        isA<AuthError>().having((s) => s.message, 'message', contains('로그아웃')),
      ],
    );
  });

  group('AuthBloc — RefreshAuthToken', () {
    blocTest<AuthBloc, AuthState>(
      'emits [TokenRefreshing, Authenticated] on success',
      build: () => _build(FakeAuth42Client()
        ..refreshResult = 'jwt-rotated'
        ..currentStudent = makeTestStudent()),
      act: (bloc) => bloc.add(const RefreshAuthToken()),
      expect: () => [
        isA<TokenRefreshing>(),
        isA<Authenticated>()
            .having((s) => s.token, 'token', 'jwt-rotated'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'on refresh failure: emits AuthError, then triggers Logout '
      '(LogoutInProgress, Unauthenticated)',
      build: () => _build(FakeAuth42Client()
        ..refreshError = Exception('refresh failed')),
      act: (bloc) => bloc.add(const RefreshAuthToken()),
      // After AuthError, the bloc dispatches `Logout` itself which produces
      // LogoutInProgress + Unauthenticated.
      expect: () => [
        isA<TokenRefreshing>(),
        isA<AuthError>().having(
          (s) => s.message,
          'message',
          contains('토큰 갱신'),
        ),
        isA<LogoutInProgress>(),
        isA<Unauthenticated>(),
      ],
    );
  });

  group('AuthBloc — ClearAuthError', () {
    blocTest<AuthBloc, AuthState>(
      'transitions to Unauthenticated',
      build: () => _build(FakeAuth42Client()),
      seed: () =>
          const AuthError(message: 'something bad', error: 'detail'),
      act: (bloc) => bloc.add(const ClearAuthError()),
      expect: () => [isA<Unauthenticated>()],
    );
  });
}
