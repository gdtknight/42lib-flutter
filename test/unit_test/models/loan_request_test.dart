import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/models/loan_request.dart';

LoanRequest _build({
  String id = 'lr-1',
  String studentId = 'stu-1',
  String bookId = 'book-1',
  LoanRequestStatus status = LoanRequestStatus.pending,
  DateTime? requestDate,
  DateTime? reviewedAt,
  String? rejectionReason,
  String? notes,
}) {
  return LoanRequest(
    id: id,
    studentId: studentId,
    bookId: bookId,
    status: status,
    requestDate: requestDate ?? DateTime(2024, 1, 1),
    reviewedAt: reviewedAt,
    rejectionReason: rejectionReason,
    notes: notes,
  );
}

void main() {
  group('LoanRequest model (T093)', () {
    test('creates valid pending request', () {
      final r = _build();
      expect(r.id, 'lr-1');
      expect(r.isPending, isTrue);
      expect(r.canBeCancelled, isTrue);
    });

    test('rejects empty studentId', () {
      expect(
        () => _build(studentId: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty bookId', () {
      expect(
        () => _build(bookId: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('approved status requires reviewedAt (VR-204)', () {
      expect(
        () => _build(status: LoanRequestStatus.approved),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('approved with reviewedAt is valid', () {
      final r = _build(
        status: LoanRequestStatus.approved,
        reviewedAt: DateTime(2024, 1, 2),
      );
      expect(r.isApproved, isTrue);
      expect(r.canBeCancelled, isFalse);
    });

    test('rejection reason length > 500 throws', () {
      expect(
        () => _build(
          status: LoanRequestStatus.rejected,
          reviewedAt: DateTime(2024, 1, 2),
          rejectionReason: 'x' * 501,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('notes length > 1000 throws', () {
      expect(
        () => _build(notes: 'x' * 1001),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('status helpers reflect enum value', () {
      expect(_build(status: LoanRequestStatus.cancelled).isCancelled, isTrue);
      expect(
        _build(
          status: LoanRequestStatus.rejected,
          reviewedAt: DateTime(2024, 1, 2),
        ).isRejected,
        isTrue,
      );
    });

    test('JSON roundtrip preserves fields', () {
      final original = _build(notes: 'hello');
      final json = original.toJson();
      final parsed = LoanRequest.fromJson(json);
      expect(parsed, equals(original)); // equality by id
      expect(parsed.notes, 'hello');
    });

    test('copyWith updates only specified fields', () {
      final r = _build();
      final copy = r.copyWith(notes: 'updated');
      expect(copy.id, r.id);
      expect(copy.notes, 'updated');
      expect(r.notes, isNull);
    });
  });
}
