import 'package:sqflite/sqflite.dart';
import '../models/book.dart';
import '../services/api/base_api_client.dart';
import 'book_repository.dart';

class BookRepositoryImpl implements BookRepository {
  final Database database;
  final BaseApiClient apiClient;

  static const String tableName = 'books';

  BookRepositoryImpl({
    required this.database,
    required this.apiClient,
  });

  @override
  Future<List<Book>> fetchBooks({int page = 1, int limit = 20}) async {
    try {
      // Try to fetch from API first
      final response = await apiClient.get(
        '/books',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final data = response as Map<String, dynamic>;
      final List<dynamic> booksData = data['data'] as List<dynamic>;
      final books = booksData.map((json) => Book.fromJson(json as Map<String, dynamic>)).toList();

      // Cache books locally
      for (final book in books) {
        await _cacheBook(book);
      }

      return books;
    } catch (e) {
      // Fallback to local cache on error
      return _getBooksFromCache(page: page, limit: limit);
    }
  }

  @override
  Future<Book?> getBookById(String id) async {
    // Check cache first
    final cached = await _getBookFromCache(id);
    if (cached != null) {
      return cached;
    }

    // Fetch from API if not in cache
    try {
      final response = await apiClient.get('/books/$id');
      final book = Book.fromJson(response as Map<String, dynamic>);
      
      // Cache the book
      await _cacheBook(book);
      
      return book;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Book>> searchBooks({
    String? title,
    String? author,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (title != null && title.isNotEmpty) {
        queryParams['title'] = title;
      }
      if (author != null && author.isNotEmpty) {
        queryParams['author'] = author;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await apiClient.get('/books', queryParameters: queryParams);
      
      final data = response as Map<String, dynamic>;
      final List<dynamic> booksData = data['data'] as List<dynamic>;
      final books = booksData.map((json) => Book.fromJson(json as Map<String, dynamic>)).toList();

      // Cache search results
      for (final book in books) {
        await _cacheBook(book);
      }

      return books;
    } catch (e) {
      // Fallback to local search
      return _searchBooksInCache(
        title: title,
        author: author,
        category: category,
        page: page,
        limit: limit,
      );
    }
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final response = await apiClient.get('/books/categories');
      final data = response as Map<String, dynamic>;
      return List<String>.from(data['categories'] as List);
    } catch (e) {
      // Fallback to cache
      return _getCategoriesFromCache();
    }
  }

  @override
  Future<void> syncWithApi() async {
    try {
      final response = await apiClient.get('/books', queryParameters: {
        'page': 1,
        'limit': 1000, // Get all books
      });

      final data = response as Map<String, dynamic>;
      final List<dynamic> booksData = data['data'] as List<dynamic>;
      
      // Clear cache and reload
      await database.delete(tableName);
      
      for (final json in booksData) {
        final book = Book.fromJson(json as Map<String, dynamic>);
        await _cacheBook(book);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Private helper methods for cache management

  Future<void> _cacheBook(Book book) async {
    await database.insert(
      tableName,
      book.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Book?> _getBookFromCache(String id) async {
    final results = await database.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    
    return Book.fromJson(results.first);
  }

  Future<List<Book>> _getBooksFromCache({int page = 1, int limit = 20}) async {
    final offset = (page - 1) * limit;
    final results = await database.query(
      tableName,
      limit: limit,
      offset: offset,
      orderBy: 'createdAt DESC',
    );

    return results.map((json) => Book.fromJson(json)).toList();
  }

  Future<List<Book>> _searchBooksInCache({
    String? title,
    String? author,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (title != null && title.isNotEmpty) {
      whereClause += 'title LIKE ?';
      whereArgs.add('%$title%');
    }

    if (author != null && author.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'author LIKE ?';
      whereArgs.add('%$author%');
    }

    if (category != null && category.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category = ?';
      whereArgs.add(category);
    }

    final offset = (page - 1) * limit;
    final results = await database.query(
      tableName,
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: limit,
      offset: offset,
      orderBy: 'createdAt DESC',
    );

    return results.map((json) => Book.fromJson(json)).toList();
  }

  Future<List<String>> _getCategoriesFromCache() async {
    final results = await database.rawQuery(
      'SELECT DISTINCT category FROM $tableName ORDER BY category',
    );

    return results.map((row) => row['category'] as String).toList();
  }
}
