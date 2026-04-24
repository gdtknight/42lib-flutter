import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/books/presentation/bloc/book_bloc.dart';
import 'package:lib_42_flutter/features/books/presentation/bloc/book_event.dart';
import 'package:lib_42_flutter/features/books/presentation/screens/book_list_screen.dart';
import 'package:lib_42_flutter/features/books/presentation/widgets/book_card.dart';

import '../../../../support/fake_book_repository.dart';

Future<void> _pump(WidgetTester tester, BookBloc bloc) async {
  await tester.pumpWidget(
    MaterialApp(home: BookListScreen(bloc: bloc)),
  );
}

/// Advance enough frames for async bloc handlers (FakeBookRepository uses
/// zero delay by default) to complete and for BlocBuilder to rebuild.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  group('BookListScreen (T038)', () {
    testWidgets('shows CircularProgressIndicator in initial state',
        (tester) async {
      final bloc = BookBloc(repository: FakeBookRepository());
      addTearDown(bloc.close);

      // Don't dispatch FetchBooks — stays BookInitial, which renders CPI.
      await _pump(tester, bloc);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders BookCard list when loaded with books', (tester) async {
      final repository = FakeBookRepository()
        ..books = [
          makeBook(id: '1', title: 'Alpha'),
          makeBook(id: '2', title: 'Beta'),
          makeBook(id: '3', title: 'Gamma'),
        ];
      final bloc = BookBloc(repository: repository);
      addTearDown(bloc.close);
      bloc.add(const FetchBooks());

      await _pump(tester, bloc);
      await _settle(tester);

      expect(find.byType(BookCard), findsNWidgets(3));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
    });

    testWidgets('shows empty message when no books and not searching',
        (tester) async {
      final repository = FakeBookRepository()..books = [];
      final bloc = BookBloc(repository: repository);
      addTearDown(bloc.close);
      bloc.add(const FetchBooks());

      await _pump(tester, bloc);
      await _settle(tester);

      expect(find.text('No books available'), findsOneWidget);
    });

    testWidgets('shows Retry button on error and re-fetches when tapped',
        (tester) async {
      final repository = FakeBookRepository()..error = Exception('boom');
      final bloc = BookBloc(repository: repository);
      addTearDown(bloc.close);
      bloc.add(const FetchBooks());

      await _pump(tester, bloc);
      await _settle(tester);

      expect(find.textContaining('Failed to load books'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);

      // Recover, then tap Retry
      repository.error = null;
      repository.books = [makeBook(id: 'retried', title: 'Retried')];

      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await _settle(tester);

      expect(find.text('Retried'), findsOneWidget);
    });

    testWidgets('toggles between Grid and List view via AppBar action',
        (tester) async {
      final repository = FakeBookRepository()..books = [makeBook(id: 'g1')];
      final bloc = BookBloc(repository: repository);
      addTearDown(bloc.close);
      bloc.add(const FetchBooks());

      await _pump(tester, bloc);
      await _settle(tester);

      // Grid view is default — AppBar shows list icon as toggle affordance.
      expect(find.byIcon(Icons.list), findsOneWidget);

      await tester.tap(find.byIcon(Icons.list));
      await tester.pump();

      expect(find.byIcon(Icons.grid_view), findsOneWidget);
    });
  });
}
