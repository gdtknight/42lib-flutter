import 'package:equatable/equatable.dart';

abstract class BookEvent extends Equatable {
  const BookEvent();

  @override
  List<Object?> get props => [];
}

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

class SearchBooks extends BookEvent {
  final String query;

  const SearchBooks({required this.query});

  @override
  List<Object?> get props => [query];
}

class FilterByCategory extends BookEvent {
  final String category;

  const FilterByCategory({required this.category});

  @override
  List<Object?> get props => [category];
}

class LoadMoreBooks extends BookEvent {
  const LoadMoreBooks();
}

class ClearSearch extends BookEvent {
  const ClearSearch();
}

class RefreshBooks extends BookEvent {
  const RefreshBooks();
}

class FetchBookById extends BookEvent {
  final String id;

  const FetchBookById({required this.id});

  @override
  List<Object?> get props => [id];
}
