import '../models/book.dart';

/// Abstract source of book data. Production wires up [BookHttpDataSource];
/// tests can inject [BookMockDataSource] for deterministic results.
abstract class BookDataSource {
  Future<List<Book>> fetchBooks({int page = 1, int limit = 20});
  Future<Book?> getBookById(String id);
  Future<List<Book>> searchBooks({String? query, String? category});
}
