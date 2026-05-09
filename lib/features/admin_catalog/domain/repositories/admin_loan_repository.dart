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

  /// T159 — Loan history with optional date-range filter (`from`/`to` are
  /// inclusive, applied against `checkoutDate`). Backend route:
  /// `GET /api/v1/loans/history?from=...&to=...`.
  Future<List<Loan>> fetchHistory({DateTime? from, DateTime? to});

  Future<Loan> approveRequest(String requestId, {int? dueInDays, String? notes});
  Future<AdminLoanRequest> rejectRequest(String requestId, String reason);
  Future<Loan> returnLoan(String loanId);
}
