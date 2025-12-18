import '../../domain/repositories/book_repository.dart';
import '../datasources/book_mock_datasource.dart';
import '../models/book.dart';

/// Implementation of BookRepository using mock data source
class BookRepositoryImpl implements BookRepository {
  final BookMockDataSource _dataSource;

  BookRepositoryImpl({BookMockDataSource? dataSource})
      : _dataSource = dataSource ?? BookMockDataSource();

  @override
  Future<List<Book>> fetchBooks({int page = 1, int limit = 20}) {
    return _dataSource.fetchBooks(page: page, limit: limit);
  }

  @override
  Future<Book?> getBookById(String id) {
    return _dataSource.getBookById(id);
  }

  @override
  Future<List<Book>> searchBooks({
    String? query,
    String? category,
  }) {
    return _dataSource.searchBooks(query: query, category: category);
  }
}
