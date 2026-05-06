import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/models/book.dart';

void main() {
  group('Book Model', () {
    test('should create a valid Book instance', () {
      final book = Book(
        id: '123e4567-e89b-12d3-a456-426614174000',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        isbn: '9780132350884',
        category: 'Programming',
        description: 'A handbook of agile software craftsmanship',
        publicationYear: 2008,
        quantity: 5,
        availableQuantity: 3,
        coverImageUrl: 'https://example.com/cover.jpg',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(book.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(book.title, 'Clean Code');
      expect(book.author, 'Robert C. Martin');
      expect(book.isbn, '9780132350884');
      expect(book.category, 'Programming');
    });

    test('should serialize to JSON correctly', () {
      final book = Book(
        id: '123e4567-e89b-12d3-a456-426614174000',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        isbn: '9780132350884',
        category: 'Programming',
        description: 'A handbook of agile software craftsmanship',
        publicationYear: 2008,
        quantity: 5,
        availableQuantity: 3,
        coverImageUrl: 'https://example.com/cover.jpg',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final json = book.toJson();

      expect(json['id'], '123e4567-e89b-12d3-a456-426614174000');
      expect(json['title'], 'Clean Code');
      expect(json['author'], 'Robert C. Martin');
      expect(json['isbn'], '9780132350884');
      expect(json['category'], 'Programming');
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'title': 'Clean Code',
        'author': 'Robert C. Martin',
        'isbn': '9780132350884',
        'category': 'Programming',
        'description': 'A handbook of agile software craftsmanship',
        'publicationYear': 2008,
        'quantity': 5,
        'availableQuantity': 3,
        'coverImageUrl': 'https://example.com/cover.jpg',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final book = Book.fromJson(json);

      expect(book.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(book.title, 'Clean Code');
      expect(book.author, 'Robert C. Martin');
      expect(book.isbn, '9780132350884');
    });

    test('should validate title is not empty (VR-001)', () {
      expect(
        () => Book(
          id: '123e4567-e89b-12d3-a456-426614174000',
          title: '',
          author: 'Robert C. Martin',
          isbn: '9780132350884',
          category: 'Programming',
          quantity: 5,
          availableQuantity: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should validate author is not empty (VR-002)', () {
      expect(
        () => Book(
          id: '123e4567-e89b-12d3-a456-426614174000',
          title: 'Clean Code',
          author: '',
          isbn: '9780132350884',
          category: 'Programming',
          quantity: 5,
          availableQuantity: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should validate ISBN-13 format (VR-003)', () {
      expect(
        () => Book(
          id: '123e4567-e89b-12d3-a456-426614174000',
          title: 'Clean Code',
          author: 'Robert C. Martin',
          isbn: 'invalid-isbn',
          category: 'Programming',
          quantity: 5,
          availableQuantity: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should validate quantity is at least 1 (VR-005)', () {
      expect(
        () => Book(
          id: '123e4567-e89b-12d3-a456-426614174000',
          title: 'Clean Code',
          author: 'Robert C. Martin',
          category: 'Programming',
          quantity: 0,
          availableQuantity: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should validate availableQuantity is between 0 and quantity (VR-006)',
        () {
      expect(
        () => Book(
          id: '123e4567-e89b-12d3-a456-426614174000',
          title: 'Clean Code',
          author: 'Robert C. Martin',
          category: 'Programming',
          quantity: 5,
          availableQuantity: 6,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should derive availability status correctly', () {
      final availableBook = Book(
        id: '123e4567-e89b-12d3-a456-426614174000',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        category: 'Programming',
        quantity: 5,
        availableQuantity: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final unavailableBook = Book(
        id: '123e4567-e89b-12d3-a456-426614174001',
        title: 'Design Patterns',
        author: 'Gang of Four',
        category: 'Programming',
        quantity: 5,
        availableQuantity: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(availableBook.isAvailable, true);
      expect(unavailableBook.isAvailable, false);
    });

    Book makeBook({
      String id = 'book-1',
      String title = 'T',
      String author = 'A',
      String category = 'C',
      int quantity = 2,
      int availableQuantity = 1,
      int? publicationYear,
    }) {
      return Book(
        id: id,
        title: title,
        author: author,
        category: category,
        quantity: quantity,
        availableQuantity: availableQuantity,
        publicationYear: publicationYear,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    }

    // ── Phase 11 80% push: validation + helper coverage ─────────────────────

    test('throws when publicationYear is below 1000', () {
      expect(
        () => makeBook(publicationYear: 999),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when publicationYear is in the far future', () {
      expect(
        () => makeBook(publicationYear: DateTime.now().year + 5),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when category is whitespace-only', () {
      expect(
        () => makeBook(category: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('copyWith preserves unmodified fields and overrides specified ones',
        () {
      final original = makeBook(title: 'Old', quantity: 5, availableQuantity: 5);
      final updated = original.copyWith(title: 'New', availableQuantity: 3);

      expect(updated.title, 'New');
      expect(updated.availableQuantity, 3);
      expect(updated.author, original.author);
      expect(updated.quantity, original.quantity);
      expect(updated.id, original.id);
    });

    test('equality is based on id', () {
      final a = makeBook(id: 'same', title: 'X');
      final b = makeBook(id: 'same', title: 'Y'); // different content, same id
      final c = makeBook(id: 'other', title: 'X');

      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(identical(a, a), isTrue);
    });

    test('toString includes id, title, and availability', () {
      final s = makeBook(id: 'b1', title: 'Hello', availableQuantity: 1, quantity: 3)
          .toString();
      expect(s, contains('b1'));
      expect(s, contains('Hello'));
      expect(s, contains('1/3'));
    });
  });
}
