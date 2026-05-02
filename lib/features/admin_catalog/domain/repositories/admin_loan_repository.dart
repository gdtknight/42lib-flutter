import '../../data/models/loan.dart';

class LoanOperationException implements Exception {
  final String code;
  final String message;
  const LoanOperationException(this.code, this.message);

  @override
  String toString() => 'LoanOperationException($code): $message';
}

abstract class AdminLoanRepository {
  Future<List<AdminLoanRequest>> fetchPendingRequests();
  Future<List<Loan>> fetchLoans({String? status});

  Future<Loan> approveRequest(String requestId, {int? dueInDays, String? notes});
  Future<AdminLoanRequest> rejectRequest(String requestId, String reason);
  Future<Loan> returnLoan(String loanId);
}
