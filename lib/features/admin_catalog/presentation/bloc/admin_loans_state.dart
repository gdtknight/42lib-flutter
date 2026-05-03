import 'package:equatable/equatable.dart';

import '../../data/models/loan.dart';

enum AdminLoanActionStatus { idle, inProgress, success, failure }

abstract class AdminLoansState extends Equatable {
  const AdminLoansState();
  @override
  List<Object?> get props => [];
}

class AdminLoansInitial extends AdminLoansState {
  const AdminLoansInitial();
}

class AdminLoansLoading extends AdminLoansState {
  const AdminLoansLoading();
}

class AdminLoansLoaded extends AdminLoansState {
  final List<AdminLoanRequest> pendingRequests;
  final List<Loan> activeLoans;
  final AdminLoanActionStatus actionStatus;
  final String? actionMessage;

  const AdminLoansLoaded({
    required this.pendingRequests,
    required this.activeLoans,
    this.actionStatus = AdminLoanActionStatus.idle,
    this.actionMessage,
  });

  AdminLoansLoaded copyWith({
    List<AdminLoanRequest>? pendingRequests,
    List<Loan>? activeLoans,
    AdminLoanActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return AdminLoansLoaded(
      pendingRequests: pendingRequests ?? this.pendingRequests,
      activeLoans: activeLoans ?? this.activeLoans,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props =>
      [pendingRequests, activeLoans, actionStatus, actionMessage];
}

class AdminLoansError extends AdminLoansState {
  final String message;
  const AdminLoansError(this.message);

  @override
  List<Object?> get props => [message];
}
