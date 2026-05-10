// T098: 42 OAuth integration test.
//
// 통합 시나리오: LoginScreen → 42 OAuth 시작 버튼 → AuthBloc → mocked
// Auth42Client → 콜백 코드 처리 → Authenticated 상태 → 화면 전이.
//
// 단위 테스트는 이미 client/storage/bloc 각각 검증 완료
// (test/services/auth/* + test/state/auth/*). 이 통합 테스트는 그 위에
// 실제 LoginScreen + AuthBloc + FakeAuth42Client를 wire-up하여 콜백
// 처리 흐름이 화면 전이까지 한 번에 동작하는지 확인.
//
// 실 OAuth는 외부 redirect (브라우저)에 의존 — 그 부분은 플랫폼별 구현
// (미구현)이라 이 테스트 범위 밖. `test/integration_test/` 경로라
// `flutter test`로 CI에서 실행됨 (root `integration_test/` device-driven
// 테스트와 다름).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/screens/mobile/auth/login_screen.dart';
import 'package:lib_42_flutter/state/auth/auth_bloc.dart';
import 'package:lib_42_flutter/state/auth/auth_event.dart';
import 'package:lib_42_flutter/state/auth/auth_state.dart';

import '../support/fake_auth_42_client.dart';
import '../support/fake_secure_storage_service.dart';

Future<void> _pumpLoginApp(
  WidgetTester tester,
  AuthBloc bloc,
) async {
  await tester.pumpWidget(MaterialApp(
    routes: {
      '/': (_) => const Scaffold(body: Text('home-after-login')),
      '/login': (_) => BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const LoginScreen(),
          ),
    },
    initialRoute: '/login',
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('42 OAuth flow (T098)', () {
    testWidgets(
        'LoginScreen renders 42 login button and brand title',
        (tester) async {
      final bloc = AuthBloc(
        auth42Client: FakeAuth42Client(),
        secureStorage: FakeSecureStorageService(),
      );
      addTearDown(bloc.close);
      await _pumpLoginApp(tester, bloc);

      expect(find.text('42 도서관'), findsOneWidget);
      expect(find.text('42 계정으로 로그인'),
          findsOneWidget);
    });

    testWidgets(
        'tapping 42 login button dispatches Login42OAuth and shows authUrl snackbar',
        (tester) async {
      final fakeClient = FakeAuth42Client()
        ..authorizationUrl = 'https://api.intra.42.fr/oauth/authorize?stub';
      final bloc = AuthBloc(
        auth42Client: fakeClient,
        secureStorage: FakeSecureStorageService(),
      );
      addTearDown(bloc.close);
      await _pumpLoginApp(tester, bloc);

      await tester.tap(find.byIcon(Icons.login));
      await tester.pumpAndSettle();

      expect(fakeClient.getAuthorizationUrlCalls, 1);
      // listener shows the URL via snackbar (TODO in production for real redirect)
      expect(find.textContaining('OAuth URL'), findsOneWidget);
    });

    testWidgets(
        'OAuth callback success → Authenticated → navigates to "/"',
        (tester) async {
      final fakeClient = FakeAuth42Client()
        ..exchangeResult = {'token': 'jwt-from-callback'}
        ..currentStudent = makeTestStudent(username: 'oauth-tester');
      final bloc = AuthBloc(
        auth42Client: fakeClient,
        secureStorage: FakeSecureStorageService(),
      );
      addTearDown(bloc.close);
      await _pumpLoginApp(tester, bloc);

      // 외부 redirect는 모킹할 수 없으므로 콜백을 직접 dispatch.
      bloc.add(const HandleOAuthCallback(code: 'integration-code'));
      await tester.pumpAndSettle();

      // LoginScreen의 listener가 Authenticated에 도달하면 '/'로 이동.
      expect(find.text('home-after-login'), findsOneWidget);
      expect(fakeClient.exchangeCalls, 1);
      expect(fakeClient.lastExchangeCode, 'integration-code');
      expect(fakeClient.getCurrentStudentCalls, 1);
    });

    testWidgets(
        'OAuth callback failure → AuthError → red snackbar message',
        (tester) async {
      final fakeClient = FakeAuth42Client()
        ..exchangeError = Exception('42 OAuth 인증에 실패했습니다');
      final bloc = AuthBloc(
        auth42Client: fakeClient,
        secureStorage: FakeSecureStorageService(),
      );
      addTearDown(bloc.close);
      await _pumpLoginApp(tester, bloc);

      bloc.add(const HandleOAuthCallback(code: 'bad-code'));
      await tester.pumpAndSettle();

      expect(find.text('home-after-login'), findsNothing);
      // Login screen still showing
      expect(find.text('42 계정으로 로그인'),
          findsOneWidget);
      // AuthError listener shows snackbar with the message
      expect(find.textContaining('OAuth 인증 중'), findsOneWidget);
    });

    testWidgets(
        'CheckAuthStatus on app start with valid token → skips login screen',
        (tester) async {
      final fakeClient = FakeAuth42Client()
        ..isAuth = true
        ..token = 'cached-jwt'
        ..currentStudent = makeTestStudent(username: 'returning-user');
      final bloc = AuthBloc(
        auth42Client: fakeClient,
        secureStorage: FakeSecureStorageService(),
      );
      addTearDown(bloc.close);
      await _pumpLoginApp(tester, bloc);

      // App boot path normally dispatches CheckAuthStatus.
      bloc.add(const CheckAuthStatus());
      await tester.pumpAndSettle();

      expect(find.text('home-after-login'), findsOneWidget);
      expect(fakeClient.isAuthenticatedCalls, 1);
    });
  });
}
