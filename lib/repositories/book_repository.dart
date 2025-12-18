import '../models/book.dart';

/// Repository interface for Book operations
/// Follows Repository pattern for data abstraction
abstract class BookRepository {
  /// Fetch all books with pagination
  /// [page] - Page number (default: 1)
  /// [limit] - Number of items per page (default: 20)
  Future<List<Book>> fetchBooks({int page = 1, int limit = 20});

  /// Get a single book by ID
  /// Returns null if not found
  Future<Book?> getBookById(String id);

  /// Search books with optional filters
  /// [title] - Search by title (case-insensitive)
  /// [author] - Search by author (case-insensitive)
  /// [category] - Filter by category
  /// [page] - Page number
  /// [limit] - Number of items per page
  Future<List<Book>> searchBooks({
    String? title,
    String? author,
    String? category,
    int page = 1,
    int limit = 20,
  });

  /// Get all available categories
  Future<List<String>> getCategories();

  /// Sync local cache with remote API
  Future<void> syncWithApi();
}
