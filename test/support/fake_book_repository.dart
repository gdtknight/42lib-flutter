import 'package:lib_42_flutter/features/books/data/models/book.dart';
import 'package:lib_42_flutter/features/books/domain/repositories/book_repository.dart';

/// Test fake that returns caller-controlled results.
/// Preferred over Mockito for simpler test setup without codegen.
class FakeBookRepository implements BookRepository {
  List<Book> books = [];
  Book? singleBook;
  Exception? error;
  Duration delay = Duration.zero;

  @override
  Future<List<Book>> fetchBooks({int page = 1, int limit = 20}) async {
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (error != null) throw error!;
    return books;
  }

  @override
  Future<Book?> getBookById(String id) async {
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (error != null) throw error!;
    return singleBook;
  }

  @override
  Future<List<Book>> searchBooks({String? query, String? category}) async {
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (error != null) throw error!;
    return books;
  }
}

Book makeBook({
  String id = 'test-1',
  String title = 'Test Book',
  String author = 'Test Author',
  String category = 'Test Category',
  String? isbn,
  int quantity = 3,
  int availableQuantity = 2,
}) {
  return Book(
    id: id,
    title: title,
    author: author,
    category: category,
    isbn: isbn,
    quantity: quantity,
    availableQuantity: availableQuantity,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}
