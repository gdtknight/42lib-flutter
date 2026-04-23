import 'package:equatable/equatable.dart';
import '../../data/models/book.dart';

abstract class BookState extends Equatable {
  const BookState();

  @override
  List<Object?> get props => [];
}

class BookInitial extends BookState {
  const BookInitial();
}

class BookLoading extends BookState {
  const BookLoading();
}

class BookLoaded extends BookState {
  final List<Book> books;
  final bool hasMore;
  final int currentPage;
  final String? activeFilter;
  final String? searchQuery;

  const BookLoaded({
    required this.books,
    this.hasMore = false,
    this.currentPage = 1,
    this.activeFilter,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [
        books,
        hasMore,
        currentPage,
        activeFilter,
        searchQuery,
      ];

  BookLoaded copyWith({
    List<Book>? books,
    bool? hasMore,
    int? currentPage,
    String? activeFilter,
    String? searchQuery,
  }) {
    return BookLoaded(
      books: books ?? this.books,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class BookError extends BookState {
  final String message;

  const BookError({required this.message});

  @override
  List<Object?> get props => [message];
}

class BookDetailLoading extends BookState {
  const BookDetailLoading();
}

class BookDetailLoaded extends BookState {
  final Book book;

  const BookDetailLoaded({required this.book});

  @override
  List<Object?> get props => [book];
}

class BookDetailError extends BookState {
  final String message;

  const BookDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}
