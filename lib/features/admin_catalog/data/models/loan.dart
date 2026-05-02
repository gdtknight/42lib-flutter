import 'package:equatable/equatable.dart';

enum LoanStatus { active, returned, overdue }

LoanStatus _parseLoanStatus(String raw) {
  switch (raw) {
    case 'active':
      return LoanStatus.active;
    case 'returned':
      return LoanStatus.returned;
    case 'overdue':
      return LoanStatus.overdue;
    default:
      throw ArgumentError('Unknown loan status: $raw');
  }
}

String _loanStatusToJson(LoanStatus s) => s.name;

enum LoanRequestStatusFront { pending, approved, rejected, cancelled }

LoanRequestStatusFront _parseRequestStatus(String raw) {
  switch (raw) {
    case 'pending':
      return LoanRequestStatusFront.pending;
    case 'approved':
      return LoanRequestStatusFront.approved;
    case 'rejected':
      return LoanRequestStatusFront.rejected;
    case 'cancelled':
      return LoanRequestStatusFront.cancelled;
    default:
      throw ArgumentError('Unknown loan request status: $raw');
  }
}

class LoanBookSummary extends Equatable {
  final String id;
  final String title;
  final String? author;

  const LoanBookSummary({required this.id, required this.title, this.author});

  factory LoanBookSummary.fromJson(Map<String, dynamic> json) {
    return LoanBookSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, title, author];
}

class LoanStudentSummary extends Equatable {
  final String id;
  final String username;
  final String? fullName;

  const LoanStudentSummary({
    required this.id,
    required this.username,
    this.fullName,
  });

  factory LoanStudentSummary.fromJson(Map<String, dynamic> json) {
    return LoanStudentSummary(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, username, fullName];
}

/// Active or completed loan record (admin view).
class Loan extends Equatable {
  final String id;
  final String studentId;
  final String bookId;
  final LoanStatus status;
  final DateTime checkoutDate;
  final DateTime dueDate;
  final DateTime? returnedDate;
  final String approvedBy;
  final String? notes;
  final LoanBookSummary? book;
  final LoanStudentSummary? student;

  const Loan({
    required this.id,
    required this.studentId,
    required this.bookId,
    required this.status,
    required this.checkoutDate,
    required this.dueDate,
    this.returnedDate,
    required this.approvedBy,
    this.notes,
    this.book,
    this.student,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      bookId: json['bookId'] as String,
      status: _parseLoanStatus(json['status'] as String),
      checkoutDate: DateTime.parse(json['checkoutDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      returnedDate: json['returnedDate'] == null
          ? null
          : DateTime.parse(json['returnedDate'] as String),
      approvedBy: json['approvedBy'] as String,
      notes: json['notes'] as String?,
      book: json['book'] is Map<String, dynamic>
          ? LoanBookSummary.fromJson(json['book'] as Map<String, dynamic>)
          : null,
      student: json['student'] is Map<String, dynamic>
          ? LoanStudentSummary.fromJson(json['student'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'bookId': bookId,
        'status': _loanStatusToJson(status),
        'checkoutDate': checkoutDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        if (returnedDate != null)
          'returnedDate': returnedDate!.toIso8601String(),
        'approvedBy': approvedBy,
        if (notes != null) 'notes': notes,
      };

  bool get isActive => status == LoanStatus.active;
  bool get isReturned => status == LoanStatus.returned;
  bool get isOverdue => status == LoanStatus.overdue;
  bool get canBeReturned =>
      status == LoanStatus.active || status == LoanStatus.overdue;

  /// Days remaining until due (negative if past due).
  int daysUntilDue(DateTime now) {
    return dueDate.difference(now).inDays;
  }

  @override
  List<Object?> get props => [
        id,
        studentId,
        bookId,
        status,
        checkoutDate,
        dueDate,
        returnedDate,
        approvedBy,
        notes,
      ];
}

/// Pending or reviewed loan request (admin view).
class AdminLoanRequest extends Equatable {
  final String id;
  final String studentId;
  final String bookId;
  final LoanRequestStatusFront status;
  final DateTime requestDate;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String? notes;
  final LoanBookSummary? book;
  final LoanStudentSummary? student;

  const AdminLoanRequest({
    required this.id,
    required this.studentId,
    required this.bookId,
    required this.status,
    required this.requestDate,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.notes,
    this.book,
    this.student,
  });

  factory AdminLoanRequest.fromJson(Map<String, dynamic> json) {
    return AdminLoanRequest(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      bookId: json['bookId'] as String,
      status: _parseRequestStatus(json['status'] as String),
      requestDate: DateTime.parse(json['requestDate'] as String),
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
      reviewedBy: json['reviewedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      notes: json['notes'] as String?,
      book: json['book'] is Map<String, dynamic>
          ? LoanBookSummary.fromJson(json['book'] as Map<String, dynamic>)
          : null,
      student: json['student'] is Map<String, dynamic>
          ? LoanStudentSummary.fromJson(json['student'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isPending => status == LoanRequestStatusFront.pending;

  @override
  List<Object?> get props => [
        id,
        studentId,
        bookId,
        status,
        requestDate,
        reviewedAt,
        reviewedBy,
        rejectionReason,
        notes,
      ];
}
