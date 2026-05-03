import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/models/student.dart';
import 'package:lib_42_flutter/state/auth/auth_bloc.dart';
import 'package:lib_42_flutter/state/auth/auth_event.dart';
import 'package:lib_42_flutter/state/auth/auth_state.dart';
import 'package:lib_42_flutter/state/loan/loan_bloc.dart';
import 'package:lib_42_flutter/widgets/loan/loan_request_button.dart';

import '../../../support/fake_loan_repositories.dart';

Student _makeStudent() => Student(
      id: 'stu-1',
      fortytwoUserId: 12345,
      username: 'alice',
      email: 'alice@42.fr',
      fullName: '앨리스',
      createdAt: DateTime(2024, 1, 1),
      lastLoginAt: DateTime(2024, 1, 2),
    );

/// Mock AuthBloc — bloc_test's MockBloc avoids the real constructor's OAuth
/// deps. Stub to expose a fixed state via `whenListen`.
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

MockAuthBloc _authBlocWith(AuthState state) {
  final mock = MockAuthBloc();
  whenListen(mock, const Stream<AuthState>.empty(), initialState: state);
  return mock;
}

Future<void> _pump(
  WidgetTester tester, {
  required AuthState authState,
  required LoanBloc loanBloc,
  required bool isAvailable,
  String bookId = 'book-1',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: _authBlocWith(authState)),
          BlocProvider<LoanBloc>.value(value: loanBloc),
        ],
        child: Scaffold(
          body: LoanRequestButton(bookId: bookId, isAvailable: isAvailable),
        ),
      ),
    ),
  );
}

void main() {
  group('LoanRequestButton (T097)', () {
    LoanBloc buildLoanBloc() {
      final bloc = LoanBloc(
        loanRequestRepository: FakeLoanRequestRepository(),
        reservationRepository: FakeReservationRepository(),
      );
      addTearDown(bloc.close);
      return bloc;
    }

    testWidgets('shows login prompt when unauthenticated', (tester) async {
      await _pump(
        tester,
        authState: const Unauthenticated(),
        loanBloc: buildLoanBloc(),
        isAvailable: true,
      );

      expect(find.text('로그인하여 대출 요청'), findsOneWidget);
      expect(find.text('대출 요청'), findsNothing);
    });

    testWidgets('shows "대출 요청" when book available and authenticated',
        (tester) async {
      await _pump(
        tester,
        authState: Authenticated(student: _makeStudent(), token: 'tok'),
        loanBloc: buildLoanBloc(),
        isAvailable: true,
      );

      expect(find.text('대출 요청'), findsOneWidget);
    });

    testWidgets('shows "예약 대기열 추가" when book unavailable',
        (tester) async {
      await _pump(
        tester,
        authState: Authenticated(student: _makeStudent(), token: 'tok'),
        loanBloc: buildLoanBloc(),
        isAvailable: false,
      );

      expect(find.text('예약 대기열 추가'), findsOneWidget);
    });

    testWidgets('opens confirmation dialog when tapped (T129)',
        (tester) async {
      await _pump(
        tester,
        authState: Authenticated(student: _makeStudent(), token: 'tok'),
        loanBloc: buildLoanBloc(),
        isAvailable: true,
      );

      await tester.tap(find.text('대출 요청'));
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('이 도서를 대출 요청하시겠습니까?'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('확인'), findsOneWidget);
    });
  });
}
