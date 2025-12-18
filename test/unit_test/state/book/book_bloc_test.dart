import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lib_42_flutter/models/book.dart';
import 'package:lib_42_flutter/repositories/book_repository.dart';
import 'package:lib_42_flutter/state/book/book_bloc.dart';
import 'package:lib_42_flutter/state/book/book_event.dart';
import 'package:lib_42_flutter/state/book/book_state.dart';

@GenerateMocks([BookRepository])
import 'book_bloc_test.mocks.dart';

void main() {
  late BookBloc bookBloc;
  late MockBookRepository mockRepository;

  setUp(() {
    mockRepository = MockBookRepository();
    bookBloc = BookBloc(repository: mockRepository);
  });

  tearDown(() {
    bookBloc.close();
  });

  final testBooks = [
    Book(
      id: '123e4567-e89b-12d3-a456-426614174000',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      category: 'Programming',
      quantity: 5,
      availableQuantity: 3,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
    Book(
      id: '123e4567-e89b-12d3-a456-426614174001',
      title: 'Design Patterns',
      author: 'Gang of Four',
      category: 'Programming',
      quantity: 3,
      availableQuantity: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
  ];

  group('BookBloc', () {
    test('initial state is BookInitial', () {
      expect(bookBloc.state, BookInitial());
    });

    blocTest<BookBloc, BookState>(
      'emits [BookLoading, BookLoaded] when FetchBooks succeeds',
      build: () {
        when(mockRepository.fetchBooks(
                page: anyNamed('page'), limit: anyNamed('limit')))
            .thenAnswer((_) async => testBooks);
        return bookBloc;
      },
      act: (bloc) => bloc.add(FetchBooks()),
      expect: () => [
        BookLoading(),
        BookLoaded(books: testBooks, hasMore: true),
      ],
      verify: (_) {
        verify(mockRepository.fetchBooks(
                page: anyNamed('page'), limit: anyNamed('limit')))
            .called(1);
      },
    );

    blocTest<BookBloc, BookState>(
      'emits [BookLoading, BookError] when FetchBooks fails',
      build: () {
        when(mockRepository.fetchBooks(
                page: anyNamed('page'), limit: anyNamed('limit')))
            .thenThrow(Exception('Network error'));
        return bookBloc;
      },
      act: (bloc) => bloc.add(FetchBooks()),
      expect: () => [
        BookLoading(),
        isA<BookError>(),
      ],
    );

    blocTest<BookBloc, BookState>(
      'emits [BookLoading, BookLoaded] when SearchBooks succeeds',
      build: () {
        when(mockRepository.searchBooks(
          title: anyNamed('title'),
          author: anyNamed('author'),
          category: anyNamed('category'),
          page: anyNamed('page'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => [testBooks[0]]);
        return bookBloc;
      },
      act: (bloc) => bloc.add(SearchBooks(query: 'Clean Code')),
      wait: const Duration(milliseconds: 600), // Debounce delay
      expect: () => [
        BookLoading(),
        BookLoaded(books: [testBooks[0]], hasMore: false),
      ],
    );

    blocTest<BookBloc, BookState>(
      'debounces search requests',
      build: () {
        when(mockRepository.searchBooks(
          title: anyNamed('title'),
          author: anyNamed('author'),
          category: anyNamed('category'),
          page: anyNamed('page'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => testBooks);
        return bookBloc;
      },
      act: (bloc) {
        bloc.add(SearchBooks(query: 'Clean'));
        bloc.add(SearchBooks(query: 'Clean Code'));
      },
      wait: const Duration(milliseconds: 600),
      expect: () => [
        BookLoading(),
        BookLoaded(books: testBooks, hasMore: true),
      ],
      verify: (_) {
        // Should only call once due to debouncing
        verify(mockRepository.searchBooks(
          title: anyNamed('title'),
          author: anyNamed('author'),
          category: anyNamed('category'),
          page: anyNamed('page'),
          limit: anyNamed('limit'),
        )).called(1);
      },
    );

    blocTest<BookBloc, BookState>(
      'emits [BookLoading, BookLoaded] when FilterByCategory succeeds',
      build: () {
        when(mockRepository.searchBooks(
          category: anyNamed('category'),
          page: anyNamed('page'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => testBooks);
        return bookBloc;
      },
      act: (bloc) => bloc.add(FilterByCategory(category: 'Programming')),
      expect: () => [
        BookLoading(),
        BookLoaded(books: testBooks, hasMore: true),
      ],
    );

    blocTest<BookBloc, BookState>(
      'supports pagination with LoadMoreBooks',
      build: () {
        when(mockRepository.fetchBooks(page: 1, limit: anyNamed('limit')))
            .thenAnswer((_) async => testBooks);
        when(mockRepository.fetchBooks(page: 2, limit: anyNamed('limit')))
            .thenAnswer((_) async => [testBooks[0]]);
        return bookBloc;
      },
      seed: () => BookLoaded(books: testBooks, hasMore: true, currentPage: 1),
      act: (bloc) => bloc.add(LoadMoreBooks()),
      expect: () => [
        BookLoaded(
          books: [...testBooks, testBooks[0]],
          hasMore: true,
          currentPage: 2,
        ),
      ],
    );

    blocTest<BookBloc, BookState>(
      'does not load more when hasMore is false',
      build: () => bookBloc,
      seed: () => BookLoaded(books: testBooks, hasMore: false, currentPage: 1),
      act: (bloc) => bloc.add(LoadMoreBooks()),
      expect: () => [],
    );

    blocTest<BookBloc, BookState>(
      'clears search results with ClearSearch',
      build: () {
        when(mockRepository.fetchBooks(
                page: anyNamed('page'), limit: anyNamed('limit')))
            .thenAnswer((_) async => testBooks);
        return bookBloc;
      },
      seed: () => BookLoaded(books: [testBooks[0]], hasMore: false),
      act: (bloc) => bloc.add(ClearSearch()),
      expect: () => [
        BookLoading(),
        BookLoaded(books: testBooks, hasMore: true),
      ],
    );
  });
}
