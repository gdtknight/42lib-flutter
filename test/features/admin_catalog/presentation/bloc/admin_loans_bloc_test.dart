import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/admin_catalog/data/models/loan.dart';
import 'package:lib_42_flutter/features/admin_catalog/domain/repositories/admin_loan_repository.dart';
import 'package:lib_42_flutter/features/admin_catalog/presentation/bloc/admin_loans_bloc.dart';
import 'package:lib_42_flutter/features/admin_catalog/presentation/bloc/admin_loans_event.dart';
import 'package:lib_42_flutter/features/admin_catalog/presentation/bloc/admin_loans_state.dart';

import '../../../../support/fake_admin_loan_repository.dart';

void main() {
  group('AdminLoansBloc', () {
    blocTest<AdminLoansBloc, AdminLoansState>(
      'load: emits [Loading, Loaded] with pending + active+overdue loans',
      build: () {
        final repo = FakeAdminLoanRepository()
          ..pendingRequests = [makeAdminLoanRequest(id: 'r1')]
          ..loansByStatus = [makeLoan(id: 'l1')];
        return AdminLoansBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const AdminLoansRequested()),
      expect: () => [
        isA<AdminLoansLoading>(),
        // Bloc fetches active and overdue separately via fake; both queries
        // return the same single mock loan, so we end up with 2 entries.
        isA<AdminLoansLoaded>()
            .having((s) => s.pendingRequests.length, 'pending', 1)
            .having((s) => s.activeLoans.length, 'active', 2),
      ],
    );

    blocTest<AdminLoansBloc, AdminLoansState>(
      'load: emits [Loading, Error] on repository failure',
      build: () {
        final repo = FakeAdminLoanRepository()..error = Exception('boom');
        return AdminLoansBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const AdminLoansRequested()),
      expect: () => [isA<AdminLoansLoading>(), isA<AdminLoansError>()],
    );

    blocTest<AdminLoansBloc, AdminLoansState>(
      'approve: removes request and prepends new loan',
      build: () {
        final repo = FakeAdminLoanRepository()
          ..approveResult = makeLoan(id: 'new-loan');
        return AdminLoansBloc(repository: repo);
      },
      seed: () => AdminLoansLoaded(
        pendingRequests: [
          makeAdminLoanRequest(id: 'r1'),
          makeAdminLoanRequest(id: 'r2'),
        ],
        activeLoans: [makeLoan(id: 'existing')],
      ),
      act: (bloc) => bloc.add(const AdminLoanApproveRequested('r1')),
      expect: () => [
        isA<AdminLoansLoaded>().having(
          (s) => s.actionStatus,
          'inProgress',
          AdminLoanActionStatus.inProgress,
        ),
        isA<AdminLoansLoaded>()
            .having((s) => s.pendingRequests.length, 'pending', 1)
            .having((s) => s.pendingRequests.first.id, 'first.id', 'r2')
            .having((s) => s.activeLoans.first.id, 'new active first', 'new-loan')
            .having((s) => s.actionStatus, 'success', AdminLoanActionStatus.success),
      ],
    );

    blocTest<AdminLoansBloc, AdminLoansState>(
      'approve: surfaces failure message via LoanOperationException',
      build: () {
        final repo = FakeAdminLoanRepository()
          ..error = const LoanOperationException('book_unavailable', '도서 가용량 0');
        return AdminLoansBloc(repository: repo);
      },
      seed: () => AdminLoansLoaded(
        pendingRequests: [makeAdminLoanRequest(id: 'r1')],
        activeLoans: const [],
      ),
      act: (bloc) => bloc.add(const AdminLoanApproveRequested('r1')),
      expect: () => [
        isA<AdminLoansLoaded>().having(
          (s) => s.actionStatus,
          'inProgress',
          AdminLoanActionStatus.inProgress,
        ),
        isA<AdminLoansLoaded>()
            .having((s) => s.actionStatus, 'failure',
                AdminLoanActionStatus.failure)
            .having((s) => s.actionMessage, 'message', '도서 가용량 0')
            .having((s) => s.pendingRequests.length, 'pending preserved', 1),
      ],
    );

    blocTest<AdminLoansBloc, AdminLoansState>(
      'reject: removes request from pending list',
      build: () => AdminLoansBloc(repository: FakeAdminLoanRepository()),
      seed: () => AdminLoansLoaded(
        pendingRequests: [makeAdminLoanRequest(id: 'r1'), makeAdminLoanRequest(id: 'r2')],
        activeLoans: const [],
      ),
      act: (bloc) =>
          bloc.add(const AdminLoanRejectRequested('r1', '동일 도서 미반납')),
      expect: () => [
        isA<AdminLoansLoaded>().having(
          (s) => s.actionStatus,
          'inProgress',
          AdminLoanActionStatus.inProgress,
        ),
        isA<AdminLoansLoaded>()
            .having((s) => s.pendingRequests.length, 'pending', 1)
            .having((s) => s.pendingRequests.first.id, 'first.id', 'r2')
            .having((s) => s.actionStatus, 'success', AdminLoanActionStatus.success),
      ],
    );

    blocTest<AdminLoansBloc, AdminLoansState>(
      'return: removes loan from active list',
      build: () => AdminLoansBloc(repository: FakeAdminLoanRepository()),
      seed: () => AdminLoansLoaded(
        pendingRequests: const [],
        activeLoans: [makeLoan(id: 'l1'), makeLoan(id: 'l2')],
      ),
      act: (bloc) => bloc.add(const AdminLoanReturnRequested('l1')),
      expect: () => [
        isA<AdminLoansLoaded>().having((s) => s.actionStatus, 'inProgress',
            AdminLoanActionStatus.inProgress),
        isA<AdminLoansLoaded>()
            .having((s) => s.activeLoans.length, 'active', 1)
            .having((s) => s.activeLoans.first.id, 'first.id', 'l2')
            .having((s) => s.actionStatus, 'success',
                AdminLoanActionStatus.success),
      ],
    );
  });
}
