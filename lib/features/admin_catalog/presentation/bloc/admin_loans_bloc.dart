import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/admin_loan_repository.dart';
import 'admin_loans_event.dart';
import 'admin_loans_state.dart';

class AdminLoansBloc extends Bloc<AdminLoansEvent, AdminLoansState> {
  final AdminLoanRepository repository;

  AdminLoansBloc({required this.repository})
      : super(const AdminLoansInitial()) {
    on<AdminLoansRequested>(_onLoad);
    on<AdminLoanApproveRequested>(_onApprove);
    on<AdminLoanRejectRequested>(_onReject);
    on<AdminLoanReturnRequested>(_onReturn);
  }

  Future<void> _onLoad(
    AdminLoansRequested event,
    Emitter<AdminLoansState> emit,
  ) async {
    emit(const AdminLoansLoading());
    try {
      final requests = await repository.fetchPendingRequests();
      // Active+overdue loans are the actionable subset for admins.
      final loans = await repository.fetchLoans(status: 'active');
      final overdue = await repository.fetchLoans(status: 'overdue');
      emit(AdminLoansLoaded(
        pendingRequests: requests,
        activeLoans: [...overdue, ...loans],
      ));
    } catch (e) {
      emit(AdminLoansError(e.toString()));
    }
  }

  Future<void> _onApprove(
    AdminLoanApproveRequested event,
    Emitter<AdminLoansState> emit,
  ) async {
    final current = state;
    if (current is! AdminLoansLoaded) return;
    emit(current.copyWith(actionStatus: AdminLoanActionStatus.inProgress));
    try {
      final loan = await repository.approveRequest(
        event.requestId,
        dueInDays: event.dueInDays,
        notes: event.notes,
      );
      emit(current.copyWith(
        pendingRequests:
            current.pendingRequests.where((r) => r.id != event.requestId).toList(),
        activeLoans: [loan, ...current.activeLoans],
        actionStatus: AdminLoanActionStatus.success,
        actionMessage: '대출 승인 완료',
      ));
    } catch (e) {
      emit(current.copyWith(
        actionStatus: AdminLoanActionStatus.failure,
        actionMessage: e is LoanOperationException ? e.message : e.toString(),
      ));
    }
  }

  Future<void> _onReject(
    AdminLoanRejectRequested event,
    Emitter<AdminLoansState> emit,
  ) async {
    final current = state;
    if (current is! AdminLoansLoaded) return;
    emit(current.copyWith(actionStatus: AdminLoanActionStatus.inProgress));
    try {
      await repository.rejectRequest(event.requestId, event.reason);
      emit(current.copyWith(
        pendingRequests:
            current.pendingRequests.where((r) => r.id != event.requestId).toList(),
        actionStatus: AdminLoanActionStatus.success,
        actionMessage: '반려 완료',
      ));
    } catch (e) {
      emit(current.copyWith(
        actionStatus: AdminLoanActionStatus.failure,
        actionMessage: e is LoanOperationException ? e.message : e.toString(),
      ));
    }
  }

  Future<void> _onReturn(
    AdminLoanReturnRequested event,
    Emitter<AdminLoansState> emit,
  ) async {
    final current = state;
    if (current is! AdminLoansLoaded) return;
    emit(current.copyWith(actionStatus: AdminLoanActionStatus.inProgress));
    try {
      await repository.returnLoan(event.loanId);
      emit(current.copyWith(
        activeLoans: current.activeLoans.where((l) => l.id != event.loanId).toList(),
        actionStatus: AdminLoanActionStatus.success,
        actionMessage: '반납 처리 완료',
      ));
    } catch (e) {
      emit(current.copyWith(
        actionStatus: AdminLoanActionStatus.failure,
        actionMessage: e is LoanOperationException ? e.message : e.toString(),
      ));
    }
  }
}
