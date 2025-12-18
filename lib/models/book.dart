import 'package:json_annotation/json_annotation.dart';

part 'book.g.dart';

@JsonSerializable()
class Book {
  final String id;
  final String title;
  final String author;
  final String? isbn;
  final String category;
  final String? description;
  final int? publicationYear;
  final int quantity;
  final int availableQuantity;
  final String? coverImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.isbn,
    required this.category,
    this.description,
    this.publicationYear,
    required this.quantity,
    required this.availableQuantity,
    this.coverImageUrl,
    required this.createdAt,
    required this.updatedAt,
  }) {
    _validate();
  }

  void _validate() {
    // VR-001: title must not be empty or whitespace-only
    if (title.trim().isEmpty) {
      throw ArgumentError('Title must not be empty');
    }

    // VR-002: author must not be empty or whitespace-only
    if (author.trim().isEmpty) {
      throw ArgumentError('Author must not be empty');
    }

    // VR-003: ISBN if provided, must match ISBN-10 or ISBN-13 format
    if (isbn != null && isbn!.isNotEmpty) {
      final cleanIsbn = isbn!.replaceAll(RegExp(r'[- ]'), '');
      if (!RegExp(r'^\d{10}$|^\d{13}$').hasMatch(cleanIsbn)) {
        throw ArgumentError('ISBN must be 10 or 13 digits');
      }
    }

    // VR-005: quantity must be at least 1
    if (quantity < 1) {
      throw ArgumentError('Quantity must be at least 1');
    }

    // VR-006: availableQuantity must be between 0 and quantity
    if (availableQuantity < 0 || availableQuantity > quantity) {
      throw ArgumentError(
          'Available quantity must be between 0 and $quantity');
    }

    // VR-007: publicationYear if provided, must be between 1000 and current year + 1
    if (publicationYear != null) {
      final currentYear = DateTime.now().year;
      if (publicationYear! < 1000 || publicationYear! > currentYear + 1) {
        throw ArgumentError(
            'Publication year must be between 1000 and ${currentYear + 1}');
      }
    }

    // VR-008: category must not be empty or whitespace-only
    if (category.trim().isEmpty) {
      throw ArgumentError('Category must not be empty');
    }
  }

  /// Availability status (derived from availableQuantity)
  bool get isAvailable => availableQuantity > 0;

  /// Create Book from JSON
  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);

  /// Convert Book to JSON
  Map<String, dynamic> toJson() => _$BookToJson(this);

  /// Create a copy of Book with updated fields
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? category,
    String? description,
    int? publicationYear,
    int? quantity,
    int? availableQuantity,
    String? coverImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      category: category ?? this.category,
      description: description ?? this.description,
      publicationYear: publicationYear ?? this.publicationYear,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Book && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author, category: $category, availableQuantity: $availableQuantity/$quantity)';
  }
}
