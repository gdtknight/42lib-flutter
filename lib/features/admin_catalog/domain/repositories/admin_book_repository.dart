import '../../../books/data/models/book.dart';

class BookInUseException implements Exception {
  final int activeLoans;
  final int pendingRequests;

  const BookInUseException({
    this.activeLoans = 0,
    this.pendingRequests = 0,
  });

  @override
  String toString() =>
      'BookInUseException(activeLoans=$activeLoans, pending=$pendingRequests)';
}

class BookConflictException implements Exception {
  final String message;
  const BookConflictException(this.message);

  @override
  String toString() => 'BookConflictException: $message';
}

class AdminBookPayload {
  final String title;
  final String author;
  final String category;
  final int quantity;
  final int availableQuantity;
  final String? isbn;
  final String? description;
  final int? publicationYear;
  final String? coverImageUrl;

  const AdminBookPayload({
    required this.title,
    required this.author,
    required this.category,
    required this.quantity,
    required this.availableQuantity,
    this.isbn,
    this.description,
    this.publicationYear,
    this.coverImageUrl,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'author': author,
        'category': category,
        'quantity': quantity,
        'availableQuantity': availableQuantity,
        if (isbn != null && isbn!.isNotEmpty) 'isbn': isbn,
        if (description != null && description!.isNotEmpty)
          'description': description,
        if (publicationYear != null) 'publicationYear': publicationYear,
        if (coverImageUrl != null && coverImageUrl!.isNotEmpty)
          'coverImageUrl': coverImageUrl,
      };
}

abstract class AdminBookRepository {
  Future<List<Book>> fetchBooks();
  Future<Book> createBook(AdminBookPayload payload);
  Future<Book> updateBook(String id, AdminBookPayload payload);

  /// Throws [BookInUseException] when the backend rejects deletion due to
  /// active loans/pending requests (HTTP 409).
  Future<void> deleteBook(String id);
}
