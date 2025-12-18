import '../models/book.dart';

/// Mock data source for books
/// Provides sample data for testing and development
class BookMockDataSource {
  static final List<Book> _mockBooks = [
    Book(
      id: '1',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      isbn: '9780132350884',
      category: 'Programming',
      publicationYear: 2008,
      quantity: 5,
      availableQuantity: 3,
      coverImageUrl: 'https://via.placeholder.com/150x200?text=Clean+Code',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Book(
      id: '2',
      title: 'Design Patterns',
      author: 'Gang of Four',
      isbn: '9780201633610',
      category: 'Programming',
      publicationYear: 1994,
      quantity: 3,
      availableQuantity: 0,
      coverImageUrl: 'https://via.placeholder.com/150x200?text=Design+Patterns',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Book(
      id: '3',
      title: 'The Pragmatic Programmer',
      author: 'Andrew Hunt, David Thomas',
      isbn: '9780135957059',
      category: 'Programming',
      publicationYear: 2019,
      quantity: 4,
      availableQuantity: 4,
      coverImageUrl: 'https://via.placeholder.com/150x200?text=Pragmatic+Programmer',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Book(
      id: '4',
      title: 'Refactoring',
      author: 'Martin Fowler',
      isbn: '9780134757599',
      category: 'Programming',
      publicationYear: 2018,
      quantity: 3,
      availableQuantity: 2,
      coverImageUrl: 'https://via.placeholder.com/150x200?text=Refactoring',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Book(
      id: '5',
      title: 'Introduction to Algorithms',
      author: 'Thomas H. Cormen',
      isbn: '9780262033848',
      category: 'Computer Science',
      publicationYear: 2009,
      quantity: 6,
      availableQuantity: 5,
      coverImageUrl: 'https://via.placeholder.com/150x200?text=Algorithms',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Book(
      id: '6',
      title: "You Don't Know JS",
      author: 'Kyle Simpson',
      isbn: '9781491904244',
      category: 'Programming',
      publicationYear: 2014,
      quantity: 4,
      availableQuantity: 1,
      coverImageUrl: 'https://via.placeholder.com/150x200?text=YDKJS',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  /// Fetch all books with pagination
  Future<List<Book>> fetchBooks({int page = 1, int limit = 20}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;

    if (startIndex >= _mockBooks.length) {
      return [];
    }

    return _mockBooks.sublist(
      startIndex,
      endIndex > _mockBooks.length ? _mockBooks.length : endIndex,
    );
  }

  /// Get a book by ID
  Future<Book?> getBookById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      return _mockBooks.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Search books by title, author, or category
  Future<List<Book>> searchBooks({
    String? query,
    String? category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    var results = List<Book>.from(_mockBooks);

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results.where((book) {
        return book.title.toLowerCase().contains(lowerQuery) ||
            book.author.toLowerCase().contains(lowerQuery) ||
            (book.isbn?.contains(lowerQuery) ?? false);
      }).toList();
    }

    if (category != null && category.isNotEmpty) {
      results = results.where((book) => book.category == category).toList();
    }

    return results;
  }
}
