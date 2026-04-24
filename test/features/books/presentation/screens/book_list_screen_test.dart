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
  await tester.pumpWidget(MaterialApp.router(routerConfig: _routerFor(bloc)));
}

/// Pump enough frames to let the BookBloc process FetchBooks and render
/// the next state. Using explicit `pump(duration)` avoids `pumpAndSettle`
/// hanging on `CircularProgressIndicator`'s infinite animation.
Future<void> _flushBlocFrames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  group('BookListScreen (T038)', () {
    testWidgets('shows CircularProgressIndicator while loading',
        (tester) async {
      final repository = FakeBookRepository()
        ..books = [makeBook()]
        ..delay = const Duration(seconds: 5); // long enough to stay in loading
      final bloc = BookBloc(repository: repository)..add(const FetchBooks());

      await _pumpScreen(tester, bloc);
      await tester.pump(); // first frame — BookInitial or transitioning

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

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
      await _flushBlocFrames(tester);

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
      await _flushBlocFrames(tester);

      expect(find.text('No books available'), findsOneWidget);

      await bloc.close();
    });

    testWidgets('shows Retry button on error and re-fetches when tapped',
        (tester) async {
      final repository = FakeBookRepository()..error = Exception('boom');
      final bloc = BookBloc(repository: repository)..add(const FetchBooks());

      await _pumpScreen(tester, bloc);
      await _flushBlocFrames(tester);

      expect(find.textContaining('Failed to load books'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);

      // Recover and retry
      repository.error = null;
      repository.books = [makeBook(id: 'retried', title: 'Retried')];

      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await _flushBlocFrames(tester);

      expect(find.text('Retried'), findsOneWidget);

      await bloc.close();
    });

    testWidgets('toggles between Grid and List view via AppBar action',
        (tester) async {
      final repository = FakeBookRepository()..books = [makeBook(id: 'g1')];
      final bloc = BookBloc(repository: repository)..add(const FetchBooks());

      await _pumpScreen(tester, bloc);
      await _flushBlocFrames(tester);

      // Grid view active → AppBar shows list icon as toggle affordance
      expect(find.byIcon(Icons.list), findsOneWidget);

      await tester.tap(find.byIcon(Icons.list));
      await tester.pump();

      expect(find.byIcon(Icons.grid_view), findsOneWidget);

      await bloc.close();
    });
  });
}
