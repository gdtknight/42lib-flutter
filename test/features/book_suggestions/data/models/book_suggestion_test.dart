import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/book_suggestions/data/models/book_suggestion.dart';
import 'package:lib_42_flutter/features/book_suggestions/data/models/collection_period.dart';

void main() {
  group('BookSuggestion model (T160)', () {
    test('parses submitted suggestion JSON', () {
      final s = BookSuggestion.fromJson(const {
        'id': 's1',
        'studentId': 'stu-1',
        'suggestedTitle': 'Effective TS',
        'suggestedAuthor': 'Vanderkam',
        'reason': '학습용',
        'collectionPeriodId': 'p1',
        'status': 'submitted',
        'submittedAt': '2024-02-01T00:00:00.000Z',
      });
      expect(s.id, 's1');
      expect(s.isSubmitted, isTrue);
      expect(s.reason, '학습용');
    });

    test('parses approved/rejected/under_review status', () {
      final approved = BookSuggestion.fromJson(const {
        'id': 's2',
        'studentId': 'stu-1',
        'suggestedTitle': 'X',
        'suggestedAuthor': 'Y',
        'collectionPeriodId': 'p1',
        'status': 'approved',
        'submittedAt': '2024-02-01T00:00:00.000Z',
      });
      expect(approved.isApproved, isTrue);

      final rejected = BookSuggestion.fromJson(const {
        'id': 's3',
        'studentId': 'stu-1',
        'suggestedTitle': 'X',
        'suggestedAuthor': 'Y',
        'collectionPeriodId': 'p1',
        'status': 'rejected',
        'submittedAt': '2024-02-01T00:00:00.000Z',
      });
      expect(rejected.isRejected, isTrue);

      final review = BookSuggestion.fromJson(const {
        'id': 's4',
        'studentId': 'stu-1',
        'suggestedTitle': 'X',
        'suggestedAuthor': 'Y',
        'collectionPeriodId': 'p1',
        'status': 'under_review',
        'submittedAt': '2024-02-01T00:00:00.000Z',
      });
      expect(review.isUnderReview, isTrue);
    });

    test('throws on unknown status', () {
      expect(
        () => BookSuggestion.fromJson(const {
          'id': 'x',
          'studentId': 's',
          'suggestedTitle': 'T',
          'suggestedAuthor': 'A',
          'collectionPeriodId': 'p',
          'status': 'pirate',
          'submittedAt': '2024-02-01T00:00:00.000Z',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('parses nested collectionPeriod summary', () {
      final s = BookSuggestion.fromJson(const {
        'id': 's5',
        'studentId': 'stu',
        'suggestedTitle': 'T',
        'suggestedAuthor': 'A',
        'collectionPeriodId': 'p1',
        'status': 'submitted',
        'submittedAt': '2024-02-01T00:00:00.000Z',
        'collectionPeriod': {
          'id': 'p1',
          'name': '2024 Q1',
          'status': 'active',
          'endDate': '2024-03-31T00:00:00.000Z',
        },
      });
      expect(s.collectionPeriod, isNotNull);
      expect(s.collectionPeriod!.name, '2024 Q1');
    });
  });

  group('CollectionPeriod model (T161)', () {
    test('parses active period and isActive helper', () {
      final p = CollectionPeriod.fromJson(const {
        'id': 'p1',
        'name': '2024 Spring',
        'startDate': '2024-03-01T00:00:00.000Z',
        'endDate': '2024-05-31T00:00:00.000Z',
        'status': 'active',
      });
      expect(p.id, 'p1');
      expect(p.isActive, isTrue);
    });

    test('throws on unknown status', () {
      expect(
        () => CollectionPeriod.fromJson(const {
          'id': 'p',
          'name': 'X',
          'startDate': '2024-01-01T00:00:00.000Z',
          'endDate': '2024-01-02T00:00:00.000Z',
          'status': 'eternal',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('daysRemaining is positive before end, 0 after', () {
      final p = CollectionPeriod.fromJson(const {
        'id': 'p',
        'name': 'X',
        'startDate': '2024-01-01T00:00:00.000Z',
        'endDate': '2024-01-15T00:00:00.000Z',
        'status': 'active',
      });
      expect(p.daysRemaining(DateTime(2024, 1, 10)), 5);
      expect(p.daysRemaining(DateTime(2024, 1, 20)), 0);
    });
  });
}
