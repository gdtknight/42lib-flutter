import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/books/presentation/bloc/book_bloc.dart';
import 'package:lib_42_flutter/features/books/presentation/bloc/book_event.dart';
import 'package:lib_42_flutter/features/books/presentation/bloc/book_state.dart';

import '../../../../support/fake_book_repository.dart';

void main() {
  group('BookBloc (T035)', () {
    late FakeBookRepository repository;

    setUp(() {
      repository = FakeBookRepository();
    });

    blocTest<BookBloc, BookState>(
      'emits [Loading, Loaded] when FetchBooks succeeds',
      build: () {
        repository.books = [makeBook(id: '1'), makeBook(id: '2')];
        return BookBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const FetchBooks()),
      expect: () => [
        isA<BookLoading>(),
        isA<BookLoaded>()
            .having((s) => s.books.length, 'books.length', 2)
            .having((s) => s.currentPage, 'currentPage', 1),
      ],
    );

    blocTest<BookBloc, BookState>(
      'emits [Loading, Error] when FetchBooks fails',
      build: () {
        repository.error = Exception('network down');
        return BookBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const FetchBooks()),
      expect: () => [
        isA<BookLoading>(),
        isA<BookError>(),
      ],
    );

    blocTest<BookBloc, BookState>(
      'debounces SearchBooks and emits Loaded after 500ms delay',
      build: () {
        repository.books = [makeBook(id: 's1', title: 'Searched')];
        return BookBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const SearchBooks(query: 'clean')),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<BookLoading>(),
        isA<BookLoaded>()
            .having((s) => s.searchQuery, 'searchQuery', 'clean')
            .having((s) => s.books.length, 'books.length', 1),
      ],
    );

    blocTest<BookBloc, BookState>(
      'SearchBooks with empty query delegates to ClearSearch',
      build: () {
        repository.books = [makeBook(id: 'c1')];
        return BookBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const SearchBooks(query: '')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<BookLoading>(),
        isA<BookLoaded>()
            .having((s) => s.searchQuery, 'searchQuery', isNull)
            .having((s) => s.books.length, 'books.length', 1),
      ],
    );

    blocTest<BookBloc, BookState>(
      'FilterByCategory emits Loaded with activeFilter',
      build: () {
        repository.books = [
          makeBook(id: 'p1', category: 'Programming'),
          makeBook(id: 'p2', category: 'Programming'),
        ];
        return BookBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const FilterByCategory(category: 'Programming')),
      expect: () => [
        isA<BookLoading>(),
        isA<BookLoaded>()
            .having((s) => s.activeFilter, 'activeFilter', 'Programming')
            .having((s) => s.books.length, 'books.length', 2),
      ],
    );

    blocTest<BookBloc, BookState>(
      'FetchBookById emits [DetailLoading, DetailLoaded] when book exists',
      build: () {
        repository.singleBook = makeBook(id: 'x1', title: 'Target');
        return BookBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const FetchBookById(id: 'x1')),
      expect: () => [
        isA<BookDetailLoading>(),
        isA<BookDetailLoaded>()
            .having((s) => s.book.id, 'book.id', 'x1')
            .having((s) => s.book.title, 'book.title', 'Target'),
      ],
    );

    blocTest<BookBloc, BookState>(
      'FetchBookById emits DetailError when book not found',
      build: () {
        repository.singleBook = null;
        return BookBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const FetchBookById(id: 'missing')),
      expect: () => [
        isA<BookDetailLoading>(),
        isA<BookDetailError>()
            .having((s) => s.message, 'message', 'Book not found'),
      ],
    );

    blocTest<BookBloc, BookState>(
      'RefreshBooks from initial state triggers fetch',
      build: () {
        repository.books = [makeBook(id: 'r1')];
        return BookBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const RefreshBooks()),
      expect: () => [
        isA<BookLoading>(),
        isA<BookLoaded>(),
      ],
    );
  });
}
