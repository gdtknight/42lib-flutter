import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/admin_catalog/data/models/loan.dart';

void main() {
  group('Loan model (T132)', () {
    test('parses loan JSON with nested book/student', () {
      final loan = Loan.fromJson(const {
        'id': 'l1',
        'studentId': 's1',
        'bookId': 'b1',
        'status': 'active',
        'checkoutDate': '2024-01-01T00:00:00.000Z',
        'dueDate': '2024-01-15T00:00:00.000Z',
        'approvedBy': 'admin-1',
        'book': {'id': 'b1', 'title': 'Clean Code', 'author': 'Martin'},
        'student': {'id': 's1', 'username': 'alice', 'fullName': '앨리스'},
      });

      expect(loan.id, 'l1');
      expect(loan.status, LoanStatus.active);
      expect(loan.book?.title, 'Clean Code');
      expect(loan.student?.fullName, '앨리스');
      expect(loan.isActive, isTrue);
      expect(loan.canBeReturned, isTrue);
    });

    test('parses overdue and returned status', () {
      final overdue = Loan.fromJson(const {
        'id': 'l2',
        'studentId': 's1',
        'bookId': 'b1',
        'status': 'overdue',
        'checkoutDate': '2024-01-01T00:00:00.000Z',
        'dueDate': '2024-01-15T00:00:00.000Z',
        'approvedBy': 'admin-1',
      });
      expect(overdue.isOverdue, isTrue);
      expect(overdue.canBeReturned, isTrue);

      final returned = Loan.fromJson(const {
        'id': 'l3',
        'studentId': 's1',
        'bookId': 'b1',
        'status': 'returned',
        'checkoutDate': '2024-01-01T00:00:00.000Z',
        'dueDate': '2024-01-15T00:00:00.000Z',
        'returnedDate': '2024-01-10T00:00:00.000Z',
        'approvedBy': 'admin-1',
      });
      expect(returned.isReturned, isTrue);
      expect(returned.canBeReturned, isFalse);
      expect(returned.returnedDate, isNotNull);
    });

    test('throws on unknown status', () {
      expect(
        () => Loan.fromJson(const {
          'id': 'l1',
          'studentId': 's1',
          'bookId': 'b1',
          'status': 'pirate',
          'checkoutDate': '2024-01-01T00:00:00.000Z',
          'dueDate': '2024-01-15T00:00:00.000Z',
          'approvedBy': 'admin-1',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('daysUntilDue is positive before due, negative after', () {
      final loan = Loan.fromJson(const {
        'id': 'l1',
        'studentId': 's1',
        'bookId': 'b1',
        'status': 'active',
        'checkoutDate': '2024-01-01T00:00:00.000Z',
        'dueDate': '2024-01-15T00:00:00.000Z',
        'approvedBy': 'admin-1',
      });
      expect(loan.daysUntilDue(DateTime(2024, 1, 10)), 5);
      expect(loan.daysUntilDue(DateTime(2024, 1, 20)), -5);
    });

    test('AdminLoanRequest parses status correctly', () {
      final req = AdminLoanRequest.fromJson(const {
        'id': 'r1',
        'studentId': 's1',
        'bookId': 'b1',
        'status': 'pending',
        'requestDate': '2024-01-01T00:00:00.000Z',
      });
      expect(req.isPending, isTrue);
      expect(req.reviewedAt, isNull);
    });
  });
}
