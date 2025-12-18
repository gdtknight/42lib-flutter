import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/book_repository.dart';
import 'book_event.dart';
import 'book_state.dart';

class BookBloc extends Bloc<BookEvent, BookState> {
  final BookRepository repository;
  Timer? _debounceTimer;

  BookBloc({required this.repository}) : super(BookInitial()) {
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
    emit(BookLoading());

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
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // If query is empty, fetch all books
    if (event.query.isEmpty) {
      add(const ClearSearch());
      return;
    }

    // Debounce search requests (500ms delay)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      emit(BookLoading());

      try {
        final books = await repository.searchBooks(
          title: event.query,
          author: event.query,
          page: 1,
          limit: 20,
        );

        emit(BookLoaded(
          books: books,
          hasMore: books.length >= 20,
          currentPage: 1,
          searchQuery: event.query,
        ));
      } catch (e) {
        emit(BookError(message: e.toString()));
      }
    });
  }

  Future<void> _onFilterByCategory(
    FilterByCategory event,
    Emitter<BookState> emit,
  ) async {
    emit(BookLoading());

    try {
      final books = await repository.searchBooks(
        category: event.category,
        page: 1,
        limit: 20,
      );

      emit(BookLoaded(
        books: books,
        hasMore: books.length >= 20,
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

    if (currentState is! BookLoaded || !currentState.hasMore) {
      return;
    }

    final nextPage = currentState.currentPage + 1;

    try {
      List<dynamic> newBooks;

      if (currentState.searchQuery != null) {
        newBooks = await repository.searchBooks(
          title: currentState.searchQuery,
          author: currentState.searchQuery,
          page: nextPage,
          limit: 20,
        );
      } else if (currentState.activeFilter != null) {
        newBooks = await repository.searchBooks(
          category: currentState.activeFilter,
          page: nextPage,
          limit: 20,
        );
      } else {
        newBooks = await repository.fetchBooks(
          page: nextPage,
          limit: 20,
        );
      }

      emit(currentState.copyWith(
        books: [...currentState.books, ...newBooks],
        hasMore: newBooks.length >= 20,
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
    emit(BookLoading());

    try {
      final books = await repository.fetchBooks(page: 1, limit: 20);

      emit(BookLoaded(
        books: books,
        hasMore: books.length >= 20,
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

    try {
      // Sync with API
      await repository.syncWithApi();

      // Reload current view
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
    } catch (e) {
      emit(BookError(message: e.toString()));
    }
  }

  Future<void> _onFetchBookById(
    FetchBookById event,
    Emitter<BookState> emit,
  ) async {
    emit(BookDetailLoading());

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

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
