import '../../data/models/book.dart';

/// Book repository interface
/// Defines contract for book data operations
abstract class BookRepository {
  /// Fetch all books with pagination
  Future<List<Book>> fetchBooks({int page = 1, int limit = 20});

  /// Get a single book by ID
  Future<Book?> getBookById(String id);

  /// Search books by query and optional category filter
  Future<List<Book>> searchBooks({
    String? query,
    String? category,
  });
}
