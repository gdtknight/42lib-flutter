import 'package:equatable/equatable.dart';

/// Base class for all Book events
abstract class BookEvent extends Equatable {
  const BookEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch all books with pagination
class FetchBooks extends BookEvent {
  final int page;
  final int limit;

  const FetchBooks({
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [page, limit];
}

/// Event to search books with query
class SearchBooks extends BookEvent {
  final String query;

  const SearchBooks({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Event to filter books by category
class FilterByCategory extends BookEvent {
  final String category;

  const FilterByCategory({required this.category});

  @override
  List<Object?> get props => [category];
}

/// Event to load more books (pagination)
class LoadMoreBooks extends BookEvent {
  const LoadMoreBooks();
}

/// Event to clear search and filters
class ClearSearch extends BookEvent {
  const ClearSearch();
}

/// Event to refresh book list
class RefreshBooks extends BookEvent {
  const RefreshBooks();
}

/// Event to fetch a single book by ID
class FetchBookById extends BookEvent {
  final String id;

  const FetchBookById({required this.id});

  @override
  List<Object?> get props => [id];
}
