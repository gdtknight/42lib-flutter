import 'package:lib_42_flutter/features/books/data/models/book.dart';
import 'package:lib_42_flutter/features/admin_catalog/domain/repositories/admin_book_repository.dart';

class FakeAdminBookRepository implements AdminBookRepository {
  List<Book> books = [];
  Book? createResult;
  Book? updateResult;
  Exception? fetchError;
  Exception? createError;
  Exception? updateError;
  Exception? deleteError;

  int fetchCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  String? lastDeletedId;
  String? lastUpdatedId;

  @override
  Future<List<Book>> fetchBooks() async {
    fetchCalls++;
    if (fetchError != null) throw fetchError!;
    return books;
  }

  @override
  Future<Book> createBook(AdminBookPayload payload) async {
    createCalls++;
    if (createError != null) throw createError!;
    return createResult ?? _bookFromPayload('new-id', payload);
  }

  @override
  Future<Book> updateBook(String id, AdminBookPayload payload) async {
    updateCalls++;
    lastUpdatedId = id;
    if (updateError != null) throw updateError!;
    return updateResult ?? _bookFromPayload(id, payload);
  }

  @override
  Future<void> deleteBook(String id) async {
    deleteCalls++;
    lastDeletedId = id;
    if (deleteError != null) throw deleteError!;
  }

  Book _bookFromPayload(String id, AdminBookPayload p) => Book(
        id: id,
        title: p.title,
        author: p.author,
        category: p.category,
        isbn: p.isbn,
        description: p.description,
        publicationYear: p.publicationYear,
        quantity: p.quantity,
        availableQuantity: p.availableQuantity,
        coverImageUrl: p.coverImageUrl,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
}

Book makeAdminBook({
  String id = 'b1',
  String title = '테스트 도서',
  String author = '저자',
  String category = 'Programming',
  int quantity = 3,
  int availableQuantity = 3,
}) {
  return Book(
    id: id,
    title: title,
    author: author,
    category: category,
    quantity: quantity,
    availableQuantity: availableQuantity,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}
