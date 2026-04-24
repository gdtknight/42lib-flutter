import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_42_flutter/features/books/presentation/bloc/book_bloc.dart';
import 'package:lib_42_flutter/features/books/presentation/bloc/book_event.dart';
import 'package:lib_42_flutter/features/books/presentation/screens/book_list_screen.dart';
import 'package:lib_42_flutter/features/books/presentation/widgets/book_card.dart';

import '../../../../support/fake_book_repository.dart';

GoRouter _routerFor(BookBloc bloc) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BookListScreen(bloc: bloc),
        ),
        GoRoute(
          path: '/books/:id',
          builder: (context, state) => const Scaffold(body: Text('detail')),
        ),
      ],
    );

Future<void> _pumpScreen(WidgetTester tester, BookBloc bloc) async {
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: _routerFor(bloc)),
  );
}

void main() {
  group('BookListScreen (T038)', () {
    testWidgets('shows CircularProgressIndicator in loading state',
        (tester) async {
      final repository = FakeBookRepository()
        ..books = [makeBook()]
        ..delay = const Duration(milliseconds: 200);
      final bloc = BookBloc(repository: repository)..add(const FetchBooks());

      await _pumpScreen(tester, bloc);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      await bloc.close();
    });

    testWidgets('renders BookCard list when loaded with books', (tester) async {
      final repository = FakeBookRepository()
        ..books = [
          makeBook(id: '1', title: 'Alpha'),
          makeBook(id: '2', title: 'Beta'),
          makeBook(id: '3', title: 'Gamma'),
        ];
      final bloc = BookBloc(repository: repository)..add(const FetchBooks());

      await _pumpScreen(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.byType(BookCard), findsNWidgets(3));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);

      await bloc.close();
    });

    testWidgets('shows empty message when no books and not searching',
        (tester) async {
      final repository = FakeBookRepository()..books = [];
      final bloc = BookBloc(repository: repository)..add(const FetchBooks());

      await _pumpScreen(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.text('No books available'), findsOneWidget);

      await bloc.close();
    });

    testWidgets('shows Retry button and calls FetchBooks again on error',
        (tester) async {
      final repository = FakeBookRepository()..error = Exception('boom');
      final bloc = BookBloc(repository: repository)..add(const FetchBooks());

      await _pumpScreen(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to load books'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);

      // Recover and retry
      repository.error = null;
      repository.books = [makeBook(id: 'retried')];

      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(BookCard), findsOneWidget);

      await bloc.close();
    });

    testWidgets('toggles between Grid and List view via AppBar action',
        (tester) async {
      final repository = FakeBookRepository()
        ..books = [makeBook(id: 'g1')];
      final bloc = BookBloc(repository: repository)..add(const FetchBooks());

      await _pumpScreen(tester, bloc);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.list), findsOneWidget); // grid active, shows list icon

      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.grid_view), findsOneWidget);

      await bloc.close();
    });
  });
}
