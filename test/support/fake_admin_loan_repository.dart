import 'package:lib_42_flutter/features/admin_catalog/data/models/loan.dart';
import 'package:lib_42_flutter/features/admin_catalog/domain/repositories/admin_loan_repository.dart';

class FakeAdminLoanRepository implements AdminLoanRepository {
  List<AdminLoanRequest> pendingRequests = [];
  List<Loan> loansByStatus = [];
  Loan? approveResult;
  AdminLoanRequest? rejectResult;
  Loan? returnResult;
  Exception? error;

  int approveCalls = 0;
  int rejectCalls = 0;
  int returnCalls = 0;

  @override
  Future<List<AdminLoanRequest>> fetchPendingRequests() async {
    if (error != null) throw error!;
    return pendingRequests;
  }

  @override
  Future<List<Loan>> fetchLoans({String? status}) async {
    if (error != null) throw error!;
    return loansByStatus;
  }

  @override
  Future<Loan> approveRequest(
    String requestId, {
    int? dueInDays,
    String? notes,
  }) async {
    approveCalls++;
    if (error != null) throw error!;
    return approveResult ?? makeLoan(id: 'loan-$requestId');
  }

  @override
  Future<AdminLoanRequest> rejectRequest(String requestId, String reason) async {
    rejectCalls++;
    if (error != null) throw error!;
    return rejectResult ??
        makeAdminLoanRequest(
          id: requestId,
          status: LoanRequestStatusFront.rejected,
          rejectionReason: reason,
        );
  }

  @override
  Future<Loan> returnLoan(String loanId) async {
    returnCalls++;
    if (error != null) throw error!;
    return returnResult ??
        makeLoan(
          id: loanId,
          status: LoanStatus.returned,
          returnedDate: DateTime(2024, 6, 1),
        );
  }
}

Loan makeLoan({
  String id = 'loan-1',
  String studentId = 'stu-1',
  String bookId = 'book-1',
  LoanStatus status = LoanStatus.active,
  DateTime? checkoutDate,
  DateTime? dueDate,
  DateTime? returnedDate,
  String approvedBy = 'admin-1',
  LoanBookSummary? book,
  LoanStudentSummary? student,
}) {
  return Loan(
    id: id,
    studentId: studentId,
    bookId: bookId,
    status: status,
    checkoutDate: checkoutDate ?? DateTime(2024, 1, 1),
    dueDate: dueDate ?? DateTime(2024, 1, 15),
    returnedDate: returnedDate,
    approvedBy: approvedBy,
    book: book,
    student: student,
  );
}

AdminLoanRequest makeAdminLoanRequest({
  String id = 'req-1',
  String studentId = 'stu-1',
  String bookId = 'book-1',
  LoanRequestStatusFront status = LoanRequestStatusFront.pending,
  DateTime? requestDate,
  DateTime? reviewedAt,
  String? rejectionReason,
  LoanBookSummary? book,
  LoanStudentSummary? student,
}) {
  return AdminLoanRequest(
    id: id,
    studentId: studentId,
    bookId: bookId,
    status: status,
    requestDate: requestDate ?? DateTime(2024, 1, 1),
    reviewedAt: reviewedAt,
    rejectionReason: rejectionReason,
    book: book,
    student: student,
  );
}
