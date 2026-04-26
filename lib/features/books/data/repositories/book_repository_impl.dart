import '../../../../app/config.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_data_source.dart';
import '../datasources/book_http_data_source.dart';
import '../models/book.dart';

/// Default repository implementation for the student-facing book browser.
///
/// Production wires up [BookHttpDataSource] to the live backend. Tests can
/// inject a [BookDataSource] (typically `BookMockDataSource`) for
/// deterministic results without hitting the network.
class BookRepositoryImpl implements BookRepository {
  final BookDataSource _dataSource;

  BookRepositoryImpl({BookDataSource? dataSource})
      : _dataSource = dataSource ??
            BookHttpDataSource(baseUrl: AppConfig.apiBaseUrl);

  @override
  Future<List<Book>> fetchBooks({int page = 1, int limit = 20}) {
    return _dataSource.fetchBooks(page: page, limit: limit);
  }

  @override
  Future<Book?> getBookById(String id) {
    return _dataSource.getBookById(id);
  }

  @override
  Future<List<Book>> searchBooks({String? query, String? category}) {
    return _dataSource.searchBooks(query: query, category: category);
  }
}
