import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/book_repository.dart';
import '../../data/models/book.dart';
import 'book_event.dart';
import 'book_state.dart';

class BookBloc extends Bloc<BookEvent, BookState> {
  static const int _defaultLimit = 20;

  final BookRepository repository;

  BookBloc({required this.repository}) : super(const BookInitial()) {
    on<FetchBooks>(_onFetchBooks);
    on<SearchBooks>(_onSearchBooks);
    on<FilterByCategory>(_onFilterByCategory);
    on<LoadMoreBooks>(_onLoadMoreBooks);
    on<ClearSearch>(_onClearSearch);
    on<RefreshBooks>(_onRefreshBooks);
    on<FetchBookById>(_onFetchBookById);
  }

  Future<void> _onFetchBooks(
    FetchBooks event,
    Emitter<BookState> emit,
  ) async {
    emit(const BookLoading());
    try {
      final books = await repository.fetchBooks(
        page: event.page,
        limit: event.limit,
      );
      emit(BookLoaded(
        books: books,
        hasMore: books.length >= event.limit,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(BookError(message: e.toString()));
    }
  }

  Future<void> _onSearchBooks(
    SearchBooks event,
    Emitter<BookState> emit,
  ) async {
    // Debouncing is handled at the UI layer (BookSearchBar widget).
    // This handler processes already-debounced semantic events.
    if (event.query.isEmpty) {
      add(const ClearSearch());
      return;
    }
    emit(const BookLoading());
    try {
      final books = await repository.searchBooks(query: event.query);
      emit(BookLoaded(
        books: books,
        hasMore: books.length >= _defaultLimit,
        currentPage: 1,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(BookError(message: e.toString()));
    }
  }

  Future<void> _onFilterByCategory(
    FilterByCategory event,
    Emitter<BookState> emit,
  ) async {
    emit(const BookLoading());
    try {
      final books = await repository.searchBooks(category: event.category);
      emit(BookLoaded(
        books: books,
        hasMore: books.length >= _defaultLimit,
        currentPage: 1,
        activeFilter: event.category,
      ));
    } catch (e) {
      emit(BookError(message: e.toString()));
    }
  }

  Future<void> _onLoadMoreBooks(
    LoadMoreBooks event,
    Emitter<BookState> emit,
  ) async {
    final currentState = state;
    if (currentState is! BookLoaded || !currentState.hasMore) return;

    final nextPage = currentState.currentPage + 1;
    try {
      final List<Book> newBooks;
      if (currentState.searchQuery != null) {
        newBooks =
            await repository.searchBooks(query: currentState.searchQuery);
      } else if (currentState.activeFilter != null) {
        newBooks =
            await repository.searchBooks(category: currentState.activeFilter);
      } else {
        newBooks = await repository.fetchBooks(
          page: nextPage,
          limit: _defaultLimit,
        );
      }
      emit(currentState.copyWith(
        books: [...currentState.books, ...newBooks],
        hasMore: newBooks.length >= _defaultLimit,
        currentPage: nextPage,
      ));
    } catch (e) {
      emit(BookError(message: e.toString()));
    }
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<BookState> emit,
  ) async {
    emit(const BookLoading());
    try {
      final books = await repository.fetchBooks(
        page: 1,
        limit: _defaultLimit,
      );
      emit(BookLoaded(
        books: books,
        hasMore: books.length >= _defaultLimit,
        currentPage: 1,
      ));
    } catch (e) {
      emit(BookError(message: e.toString()));
    }
  }

  Future<void> _onRefreshBooks(
    RefreshBooks event,
    Emitter<BookState> emit,
  ) async {
    final currentState = state;
    if (currentState is BookLoaded) {
      if (currentState.searchQuery != null) {
        add(SearchBooks(query: currentState.searchQuery!));
      } else if (currentState.activeFilter != null) {
        add(FilterByCategory(category: currentState.activeFilter!));
      } else {
        add(const FetchBooks());
      }
    } else {
      add(const FetchBooks());
    }
  }

  Future<void> _onFetchBookById(
    FetchBookById event,
    Emitter<BookState> emit,
  ) async {
    emit(const BookDetailLoading());
    try {
      final book = await repository.getBookById(event.id);
      if (book == null) {
        emit(const BookDetailError(message: 'Book not found'));
        return;
      }
      emit(BookDetailLoaded(book: book));
    } catch (e) {
      emit(BookDetailError(message: e.toString()));
    }
  }
}
