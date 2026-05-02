import 'package:equatable/equatable.dart';

abstract class AdminLoansEvent extends Equatable {
  const AdminLoansEvent();
  @override
  List<Object?> get props => [];
}

class AdminLoansRequested extends AdminLoansEvent {
  const AdminLoansRequested();
}

class AdminLoanApproveRequested extends AdminLoansEvent {
  final String requestId;
  final int? dueInDays;
  final String? notes;
  const AdminLoanApproveRequested(this.requestId, {this.dueInDays, this.notes});

  @override
  List<Object?> get props => [requestId, dueInDays, notes];
}

class AdminLoanRejectRequested extends AdminLoansEvent {
  final String requestId;
  final String reason;
  const AdminLoanRejectRequested(this.requestId, this.reason);

  @override
  List<Object?> get props => [requestId, reason];
}

class AdminLoanReturnRequested extends AdminLoansEvent {
  final String loanId;
  const AdminLoanReturnRequested(this.loanId);

  @override
  List<Object?> get props => [loanId];
}
