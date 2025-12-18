import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:lib_42_flutter/models/book.dart';
import 'package:lib_42_flutter/state/book/book_bloc.dart';
import 'package:lib_42_flutter/state/book/book_event.dart';
import 'package:lib_42_flutter/state/book/book_state.dart';
import 'package:lib_42_flutter/screens/mobile/home/home_screen.dart';

@GenerateMocks([BookBloc])
import 'home_screen_test.mocks.dart';

void main() {
  late MockBookBloc mockBookBloc;

  setUp(() {
    mockBookBloc = MockBookBloc();
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

  Widget createHomeScreen() {
    return BlocProvider<BookBloc>.value(
      value: mockBookBloc,
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  testWidgets('HomeScreen displays loading indicator when loading',
      (WidgetTester tester) async {
    when(mockBookBloc.state).thenReturn(BookLoading());
    when(mockBookBloc.stream).thenAnswer((_) => Stream.value(BookLoading()));

    await tester.pumpWidget(createHomeScreen());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('HomeScreen displays books when loaded',
      (WidgetTester tester) async {
    when(mockBookBloc.state)
        .thenReturn(BookLoaded(books: testBooks, hasMore: false));
    when(mockBookBloc.stream).thenAnswer(
        (_) => Stream.value(BookLoaded(books: testBooks, hasMore: false)));

    await tester.pumpWidget(createHomeScreen());
    await tester.pumpAndSettle();

    expect(find.text('Clean Code'), findsOneWidget);
    expect(find.text('Design Patterns'), findsOneWidget);
  });

  testWidgets('HomeScreen displays error message when error occurs',
      (WidgetTester tester) async {
    when(mockBookBloc.state).thenReturn(BookError(message: 'Network error'));
    when(mockBookBloc.stream)
        .thenAnswer((_) => Stream.value(BookError(message: 'Network error')));

    await tester.pumpWidget(createHomeScreen());
    await tester.pumpAndSettle();

    expect(find.text('Network error'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('HomeScreen shows search bar', (WidgetTester tester) async {
    when(mockBookBloc.state).thenReturn(BookInitial());
    when(mockBookBloc.stream).thenAnswer((_) => Stream.value(BookInitial()));

    await tester.pumpWidget(createHomeScreen());

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('HomeScreen triggers search when text is entered',
      (WidgetTester tester) async {
    when(mockBookBloc.state).thenReturn(BookInitial());
    when(mockBookBloc.stream).thenAnswer((_) => Stream.value(BookInitial()));

    await tester.pumpWidget(createHomeScreen());

    await tester.enterText(find.byType(TextField), 'Clean Code');
    await tester.pump(const Duration(milliseconds: 600));

    verify(mockBookBloc.add(SearchBooks(query: 'Clean Code'))).called(1);
  });

  testWidgets('HomeScreen shows category filters', (WidgetTester tester) async {
    when(mockBookBloc.state).thenReturn(BookInitial());
    when(mockBookBloc.stream).thenAnswer((_) => Stream.value(BookInitial()));

    await tester.pumpWidget(createHomeScreen());

    expect(find.text('전체'), findsOneWidget);
    expect(find.text('프로그래밍'), findsOneWidget);
    expect(find.text('디자인'), findsOneWidget);
  });

  testWidgets('HomeScreen triggers filter when category is selected',
      (WidgetTester tester) async {
    when(mockBookBloc.state).thenReturn(BookInitial());
    when(mockBookBloc.stream).thenAnswer((_) => Stream.value(BookInitial()));

    await tester.pumpWidget(createHomeScreen());

    await tester.tap(find.text('프로그래밍'));
    await tester.pumpAndSettle();

    verify(mockBookBloc.add(FilterByCategory(category: 'Programming')))
        .called(1);
  });

  testWidgets('HomeScreen fetches books on initial load',
      (WidgetTester tester) async {
    when(mockBookBloc.state).thenReturn(BookInitial());
    when(mockBookBloc.stream).thenAnswer((_) => Stream.value(BookInitial()));

    await tester.pumpWidget(createHomeScreen());

    verify(mockBookBloc.add(FetchBooks())).called(1);
  });

  testWidgets('HomeScreen supports pull-to-refresh',
      (WidgetTester tester) async {
    when(mockBookBloc.state)
        .thenReturn(BookLoaded(books: testBooks, hasMore: false));
    when(mockBookBloc.stream).thenAnswer(
        (_) => Stream.value(BookLoaded(books: testBooks, hasMore: false)));

    await tester.pumpWidget(createHomeScreen());
    await tester.pumpAndSettle();

    await tester.drag(find.text('Clean Code'), const Offset(0, 300));
    await tester.pumpAndSettle();

    verify(mockBookBloc.add(FetchBooks())).called(greaterThanOrEqualTo(1));
  });

  testWidgets('HomeScreen loads more books when scrolling to bottom',
      (WidgetTester tester) async {
    when(mockBookBloc.state)
        .thenReturn(BookLoaded(books: testBooks, hasMore: true));
    when(mockBookBloc.stream).thenAnswer(
        (_) => Stream.value(BookLoaded(books: testBooks, hasMore: true)));

    await tester.pumpWidget(createHomeScreen());
    await tester.pumpAndSettle();

    await tester.drag(find.text('Design Patterns'), const Offset(0, -300));
    await tester.pumpAndSettle();

    verify(mockBookBloc.add(LoadMoreBooks())).called(greaterThanOrEqualTo(1));
  });

  testWidgets('HomeScreen navigates to book detail when card is tapped',
      (WidgetTester tester) async {
    when(mockBookBloc.state)
        .thenReturn(BookLoaded(books: testBooks, hasMore: false));
    when(mockBookBloc.stream).thenAnswer(
        (_) => Stream.value(BookLoaded(books: testBooks, hasMore: false)));

    await tester.pumpWidget(createHomeScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clean Code'));
    await tester.pumpAndSettle();

    expect(find.text('책 상세'), findsOneWidget);
  });
}
