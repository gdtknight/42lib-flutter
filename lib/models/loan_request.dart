import 'package:json_annotation/json_annotation.dart';

part 'loan_request.g.dart';

enum LoanRequestStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

@JsonSerializable()
class LoanRequest {
  final String id;
  final String studentId;
  final String bookId;
  final LoanRequestStatus status;
  final DateTime requestDate;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String? notes;

  LoanRequest({
    required this.id,
    required this.studentId,
    required this.bookId,
    required this.status,
    required this.requestDate,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.notes,
  }) {
    _validate();
  }

  void _validate() {
    // VR-201: studentId must exist (enforced at repository level)
    if (studentId.trim().isEmpty) {
      throw ArgumentError('Student ID must not be empty');
    }

    // VR-202: bookId must exist (enforced at repository level)
    if (bookId.trim().isEmpty) {
      throw ArgumentError('Book ID must not be empty');
    }

    // VR-204: reviewedAt required if status is approved or rejected
    if ((status == LoanRequestStatus.approved ||
            status == LoanRequestStatus.rejected) &&
        reviewedAt == null) {
      throw ArgumentError(
          'Reviewed date required for approved/rejected requests');
    }

    // Rejection reason length constraint
    if (rejectionReason != null && rejectionReason!.length > 500) {
      throw ArgumentError('Rejection reason must not exceed 500 characters');
    }

    // Notes length constraint
    if (notes != null && notes!.length > 1000) {
      throw ArgumentError('Notes must not exceed 1000 characters');
    }
  }

  /// Check if request is pending
  bool get isPending => status == LoanRequestStatus.pending;

  /// Check if request is approved
  bool get isApproved => status == LoanRequestStatus.approved;

  /// Check if request is rejected
  bool get isRejected => status == LoanRequestStatus.rejected;

  /// Check if request is cancelled
  bool get isCancelled => status == LoanRequestStatus.cancelled;

  /// Check if request can be cancelled by student
  bool get canBeCancelled => status == LoanRequestStatus.pending;

  /// Create LoanRequest from JSON
  factory LoanRequest.fromJson(Map<String, dynamic> json) =>
      _$LoanRequestFromJson(json);

  /// Convert LoanRequest to JSON
  Map<String, dynamic> toJson() => _$LoanRequestToJson(this);

  /// Create a copy of LoanRequest with updated fields
  LoanRequest copyWith({
    String? id,
    String? studentId,
    String? bookId,
    LoanRequestStatus? status,
    DateTime? requestDate,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    String? notes,
  }) {
    return LoanRequest(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      bookId: bookId ?? this.bookId,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LoanRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LoanRequest(id: $id, studentId: $studentId, bookId: $bookId, status: $status)';
  }
}
