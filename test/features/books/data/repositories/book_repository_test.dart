import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/books/data/datasources/book_mock_datasource.dart';
import 'package:lib_42_flutter/features/books/data/repositories/book_repository_impl.dart';

void main() {
  group('BookRepositoryImpl (T034)', () {
    late BookRepositoryImpl repository;

    setUp(() {
      // Inject the mock data source so the repo doesn't try to hit the network
      // in unit tests. Production wires up BookHttpDataSource by default.
      repository = BookRepositoryImpl(dataSource: BookMockDataSource());
    });

    test('should fetch all mock books on first page', () async {
      final books = await repository.fetchBooks();

      expect(books, isNotEmpty);
      expect(books.first.title, isA<String>());
      expect(books.first.title.trim(), isNotEmpty);
    });

    test('should return empty list beyond available pages', () async {
      final books = await repository.fetchBooks(page: 100);

      expect(books, isEmpty);
    });

    test('should respect limit parameter', () async {
      final books = await repository.fetchBooks(limit: 2);

      expect(books.length, lessThanOrEqualTo(2));
    });

    test('should return book by valid id', () async {
      final book = await repository.getBookById('1');

      expect(book, isNotNull);
      expect(book!.id, '1');
    });

    test('should return null for unknown id', () async {
      final book = await repository.getBookById('non-existent-id');

      expect(book, isNull);
    });

    test('should filter by query (title/author/isbn)', () async {
      final results = await repository.searchBooks(query: 'Clean');

      expect(results, isNotEmpty);
      expect(
        results.every((b) =>
            b.title.toLowerCase().contains('clean') ||
            b.author.toLowerCase().contains('clean') ||
            (b.isbn?.contains('clean') ?? false)),
        isTrue,
      );
    });

    test('should return empty list for non-matching query', () async {
      final results =
          await repository.searchBooks(query: 'zzzzzz-no-match-zzzzzz');

      expect(results, isEmpty);
    });

    test('should filter by category', () async {
      final results = await repository.searchBooks(category: 'Programming');

      expect(results, isNotEmpty);
      expect(results.every((b) => b.category == 'Programming'), isTrue);
    });
  });
}
