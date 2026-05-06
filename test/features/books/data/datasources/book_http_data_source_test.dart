import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/books/data/datasources/book_http_data_source.dart';

import '../../../../support/fake_dio_adapter.dart';

BookHttpDataSource _build(FakeDioAdapter adapter) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.test',
    validateStatus: (s) => s != null && s < 500,
  ));
  dio.httpClientAdapter = adapter;
  return BookHttpDataSource(baseUrl: 'https://api.test', httpClient: dio);
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

void main() {
  group('BookHttpDataSource', () {
    test('fetchBooks returns parsed list and passes pagination params',
        () async {
      final adapter = FakeDioAdapter()..enqueue(bodyList: [_bookJson]);
      final ds = _build(adapter);

      final books = await ds.fetchBooks(page: 2, limit: 50);

      expect(books, hasLength(1));
      expect(books.first.title, '클린 아키텍처');
      expect(adapter.requests.single.path, '/v1/books');
      expect(adapter.requests.single.queryParameters, {'page': 2, 'limit': 50});
    });

    test('fetchBooks returns empty when response is missing the data array',
        () async {
      final adapter = FakeDioAdapter()..enqueue(rawBody: '{"unexpected": 1}');
      final ds = _build(adapter);

      final books = await ds.fetchBooks();
      expect(books, isEmpty);
    });

    test('getBookById returns Book on 200', () async {
      final adapter = FakeDioAdapter()..enqueue(body: _bookJson);
      final ds = _build(adapter);

      final book = await ds.getBookById('b1');

      expect(book?.id, 'b1');
      expect(adapter.requests.single.path, '/v1/books/b1');
    });

    test('getBookById returns null on 404', () async {
      final adapter = FakeDioAdapter()..enqueueDioError(statusCode: 404);
      final ds = _build(adapter);

      final book = await ds.getBookById('missing');
      expect(book, isNull);
    });

    test('getBookById rethrows for other DioException statuses', () async {
      final adapter = FakeDioAdapter()..enqueueDioError(statusCode: 500);
      final ds = _build(adapter);

      await expectLater(
        ds.getBookById('boom'),
        throwsA(isA<DioException>()),
      );
    });

    test('searchBooks maps query to title and includes category', () async {
      final adapter = FakeDioAdapter()..enqueue(bodyList: [_bookJson]);
      final ds = _build(adapter);

      await ds.searchBooks(query: '클린', category: 'Programming');

      final qp = adapter.requests.single.queryParameters;
      expect(qp['title'], '클린');
      expect(qp['category'], 'Programming');
      expect(qp['page'], 1);
      expect(qp['limit'], 50);
    });

    test('searchBooks omits empty query and category', () async {
      final adapter = FakeDioAdapter()..enqueue(bodyList: const []);
      final ds = _build(adapter);

      await ds.searchBooks(query: '', category: '');

      final qp = adapter.requests.single.queryParameters;
      expect(qp.containsKey('title'), isFalse);
      expect(qp.containsKey('category'), isFalse);
    });
  });
}
