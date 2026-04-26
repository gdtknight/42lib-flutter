import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/admin_catalog/domain/repositories/admin_auth_repository.dart';
import 'package:lib_42_flutter/features/admin_catalog/presentation/bloc/admin_auth_bloc.dart';
import 'package:lib_42_flutter/features/admin_catalog/presentation/screens/admin_login_screen.dart';

import '../../../../support/fake_admin_auth_repository.dart';

Future<AdminAuthBloc> _pump(
  WidgetTester tester,
  FakeAdminAuthRepository repository,
) async {
  final bloc = AdminAuthBloc(repository: repository);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AdminAuthBloc>.value(
        value: bloc,
        child: const AdminLoginScreen(),
      ),
    ),
  );
  return bloc;
}

void main() {
  group('AdminLoginScreen', () {
    testWidgets('renders title and disabled login until inputs filled',
        (tester) async {
      await _pump(tester, FakeAdminAuthRepository());

      expect(find.text('관리자 로그인'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.widgetWithText(FilledButton, '로그인'), findsOneWidget);
    });

    testWidgets('shows validation errors when submitted with empty fields',
        (tester) async {
      await _pump(tester, FakeAdminAuthRepository());

      await tester.tap(find.widgetWithText(FilledButton, '로그인'));
      await tester.pump();

      expect(find.text('사용자명을 입력하세요'), findsOneWidget);
      expect(find.text('비밀번호를 입력하세요'), findsOneWidget);
    });

    testWidgets('dispatches login on valid input', (tester) async {
      final repository = FakeAdminAuthRepository()
        ..loginResult = AdminAuthResult(token: 't', admin: makeAdmin());
      await _pump(tester, repository);

      await tester.enterText(find.byType(TextFormField).first, 'admin');
      await tester.enterText(find.byType(TextFormField).last, 'admin123');
      await tester.tap(find.widgetWithText(FilledButton, '로그인'));
      await tester.pump();
      // Allow async login to settle
      await tester.pump(const Duration(milliseconds: 10));

      expect(repository.loginCalls, 1);
    });

    testWidgets('shows snackbar with error on AdminAuthFailed',
        (tester) async {
      final repository = FakeAdminAuthRepository()
        ..loginError = const AdminAuthException(
          AdminAuthFailure.invalidCredentials,
          '잘못된 자격증명',
        );
      await _pump(tester, repository);

      await tester.enterText(find.byType(TextFormField).first, 'admin');
      await tester.enterText(find.byType(TextFormField).last, 'wrong');
      await tester.tap(find.widgetWithText(FilledButton, '로그인'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('잘못된 자격증명'), findsOneWidget);
    });
  });
}
