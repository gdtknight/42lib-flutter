import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lib_42_flutter/models/book.dart';
import 'package:lib_42_flutter/repositories/book_repository.dart';
import 'package:lib_42_flutter/repositories/book_repository_impl.dart';
import 'package:lib_42_flutter/services/api/base_api_client.dart';
import 'package:sqflite/sqflite.dart';

@GenerateMocks([Database, BaseApiClient])
import 'book_repository_test.mocks.dart';

void main() {
  late BookRepository repository;
  late MockDatabase mockDatabase;
  late MockBaseApiClient mockApiClient;

  setUp(() {
    mockDatabase = MockDatabase();
    mockApiClient = MockBaseApiClient();
    repository = BookRepositoryImpl(
      database: mockDatabase,
      apiClient: mockApiClient,
    );
  });

  group('BookRepository', () {
    final testBook = Book(
      id: '123e4567-e89b-12d3-a456-426614174000',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      isbn: '9780132350884',
      category: 'Programming',
      quantity: 5,
      availableQuantity: 3,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('should fetch books from API and cache locally', () async {
      when(mockApiClient.get('/books'))
          .thenAnswer((_) async => {
                'data': [testBook.toJson()],
                'total': 1,
              });

      when(mockDatabase.insert(
        'books',
        any,
        conflictAlgorithm: ConflictAlgorithm.replace,
      )).thenAnswer((_) async => 1);

      final result = await repository.fetchBooks();

      expect(result.length, 1);
      expect(result.first.id, testBook.id);
      verify(mockApiClient.get('/books')).called(1);
      verify(mockDatabase.insert('books', any,
              conflictAlgorithm: ConflictAlgorithm.replace))
          .called(1);
    });

    test('should fetch book by id from cache first', () async {
      when(mockDatabase.query(
        'books',
        where: 'id = ?',
        whereArgs: [testBook.id],
      )).thenAnswer((_) async => [testBook.toJson()]);

      final result = await repository.getBookById(testBook.id);

      expect(result, isNotNull);
      expect(result!.id, testBook.id);
      verify(mockDatabase.query('books',
              where: 'id = ?', whereArgs: [testBook.id]))
          .called(1);
      verifyNever(mockApiClient.get(any));
    });

    test('should fetch book by id from API if not in cache', () async {
      when(mockDatabase.query(
        'books',
        where: 'id = ?',
        whereArgs: [testBook.id],
      )).thenAnswer((_) async => []);

      when(mockApiClient.get('/books/${testBook.id}'))
          .thenAnswer((_) async => testBook.toJson());

      when(mockDatabase.insert(
        'books',
        any,
        conflictAlgorithm: ConflictAlgorithm.replace,
      )).thenAnswer((_) async => 1);

      final result = await repository.getBookById(testBook.id);

      expect(result, isNotNull);
      expect(result!.id, testBook.id);
      verify(mockApiClient.get('/books/${testBook.id}')).called(1);
      verify(mockDatabase.insert('books', any,
              conflictAlgorithm: ConflictAlgorithm.replace))
          .called(1);
    });

    test('should search books by title', () async {
      when(mockApiClient.get('/books', queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => {
                'data': [testBook.toJson()],
                'total': 1,
              });

      final result = await repository.searchBooks(title: 'Clean Code');

      expect(result.length, 1);
      expect(result.first.title, 'Clean Code');
      verify(mockApiClient.get('/books',
              queryParameters: anyNamed('queryParameters')))
          .called(1);
    });

    test('should search books by author', () async {
      when(mockApiClient.get('/books', queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => {
                'data': [testBook.toJson()],
                'total': 1,
              });

      final result = await repository.searchBooks(author: 'Robert');

      expect(result.length, 1);
      expect(result.first.author, contains('Robert'));
      verify(mockApiClient.get('/books',
              queryParameters: anyNamed('queryParameters')))
          .called(1);
    });

    test('should filter books by category', () async {
      when(mockApiClient.get('/books', queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => {
                'data': [testBook.toJson()],
                'total': 1,
              });

      final result = await repository.searchBooks(category: 'Programming');

      expect(result.length, 1);
      expect(result.first.category, 'Programming');
      verify(mockApiClient.get('/books',
              queryParameters: anyNamed('queryParameters')))
          .called(1);
    });

    test('should support pagination', () async {
      when(mockApiClient.get('/books', queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => {
                'data': [testBook.toJson()],
                'total': 1,
                'page': 2,
                'limit': 20,
              });

      final result = await repository.fetchBooks(page: 2, limit: 20);

      expect(result.length, 1);
      verify(mockApiClient.get('/books',
              queryParameters: anyNamed('queryParameters')))
          .called(1);
    });

    test('should return empty list when no books found', () async {
      when(mockApiClient.get('/books', queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => {
                'data': [],
                'total': 0,
              });

      final result = await repository.searchBooks(title: 'NonExistent');

      expect(result, isEmpty);
    });
  });
}
