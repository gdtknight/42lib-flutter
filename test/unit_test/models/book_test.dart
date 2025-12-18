import 'package:flutter_test/flutter_test.dart';
import 'package:ft_transcendence/models/book.dart';

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

    test('should validate availableQuantity is between 0 and quantity (VR-006)', () {
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
  });
}
