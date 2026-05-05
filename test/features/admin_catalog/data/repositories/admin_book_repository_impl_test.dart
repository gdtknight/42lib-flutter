import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/admin_catalog/data/repositories/admin_book_repository_impl.dart';
import 'package:lib_42_flutter/features/admin_catalog/domain/repositories/admin_book_repository.dart';

import '../../../../support/fake_dio_adapter.dart';
import '../../../../support/fake_secure_storage_service.dart';

AdminBookRepositoryImpl _build(FakeDioAdapter adapter, {String? adminToken}) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.test',
    validateStatus: (s) => s != null && s < 500,
  ));
  dio.httpClientAdapter = adapter;
  return AdminBookRepositoryImpl(
    baseUrl: 'https://api.test',
    httpClient: dio,
    storage: FakeSecureStorageService(adminToken: adminToken),
  );
}

const _bookJson = {
  'id': 'b1',
  'title': '클린 아키텍처',
  'author': 'R. Martin',
  'category': 'Programming',
  'isbn': '9780134494166',
  'description': null,
  'publicationYear': 2017,
  'quantity': 3,
  'availableQuantity': 2,
  'coverImageUrl': null,
  'createdAt': '2024-01-01T00:00:00.000Z',
  'updatedAt': '2024-01-01T00:00:00.000Z',
};

const _validPayload = AdminBookPayload(
  title: '클린 아키텍처',
  author: 'R. Martin',
  category: 'Programming',
  quantity: 3,
  availableQuantity: 2,
);

void main() {
  group('AdminBookRepositoryImpl', () {
    test('fetchBooks parses 200 response into Book list', () async {
      final adapter = FakeDioAdapter()..enqueue(bodyList: [_bookJson]);
      final repo = _build(adapter);

      final books = await repo.fetchBooks();

      expect(books, hasLength(1));
      expect(books.first.title, '클린 아키텍처');
      expect(books.first.quantity, 3);
      expect(adapter.requests.single.path, '/v1/books');
      expect(adapter.requests.single.queryParameters,
          {'page': 1, 'limit': 200});
    });

    test('fetchBooks throws on non-200', () async {
      // 4xx stays under the 500 threshold so the repo path (not Dio) rejects.
      final adapter = FakeDioAdapter()
        ..enqueue(statusCode: 401, body: {'error': 'unauthorized'});
      final repo = _build(adapter);

      await expectLater(repo.fetchBooks(), throwsA(isA<BookConflictException>()));
    });

    test('createBook posts payload and returns Book on 201', () async {
      final adapter = FakeDioAdapter()
        ..enqueue(statusCode: 201, body: _bookJson);
      final repo = _build(adapter);

      final book = await repo.createBook(_validPayload);

      expect(book.id, 'b1');
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/v1/books');
      expect(adapter.lastRequestBody['title'], '클린 아키텍처');
    });

    test('createBook surfaces 400 validation error message', () async {
      final adapter = FakeDioAdapter()
        ..enqueue(statusCode: 400, body: {'error': 'ISBN already exists'});
      final repo = _build(adapter);

      await expectLater(
        repo.createBook(_validPayload),
        throwsA(isA<BookConflictException>().having(
            (e) => e.message, 'message', contains('ISBN'))),
      );
    });

    test('updateBook puts to /v1/books/:id and returns Book on 200', () async {
      final adapter = FakeDioAdapter()
        ..enqueue(statusCode: 200, body: _bookJson);
      final repo = _build(adapter);

      final book = await repo.updateBook('b1', _validPayload);

      expect(book.id, 'b1');
      expect(adapter.requests.single.method, 'PUT');
      expect(adapter.requests.single.path, '/v1/books/b1');
    });

    test('deleteBook returns normally on 204', () async {
      final adapter = FakeDioAdapter()..enqueue(statusCode: 204);
      final repo = _build(adapter);

      await repo.deleteBook('b1');

      expect(adapter.requests.single.method, 'DELETE');
    });

    test('deleteBook throws BookInUseException on 409 with active loans',
        () async {
      final adapter = FakeDioAdapter()
        ..enqueue(
          statusCode: 409,
          body: {'activeLoans': 2, 'pendingRequests': 1},
        );
      final repo = _build(adapter);

      await expectLater(
        repo.deleteBook('b1'),
        throwsA(isA<BookInUseException>()
            .having((e) => e.activeLoans, 'activeLoans', 2)
            .having((e) => e.pendingRequests, 'pendingRequests', 1)),
      );
    });

    test('admin token is attached as Authorization header when present',
        () async {
      final adapter = FakeDioAdapter()..enqueue(bodyList: const []);
      final repo = _build(adapter, adminToken: 'tok-xyz');

      await repo.fetchBooks();

      expect(adapter.requests.single.headers['Authorization'],
          'Bearer tok-xyz');
    });

    test('Authorization header is omitted when admin token is null', () async {
      final adapter = FakeDioAdapter()..enqueue(bodyList: const []);
      final repo = _build(adapter, adminToken: null);

      await repo.fetchBooks();

      expect(adapter.requests.single.headers.containsKey('Authorization'),
          isFalse);
    });
  });
}
