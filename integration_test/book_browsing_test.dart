import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lib_42_flutter/features/books/presentation/widgets/book_card.dart';
import 'package:lib_42_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Book Browsing Flow (T039)', () {
    testWidgets('loads book list from mock data on app start', (tester) async {
      app.main();
      // BookMockDataSource has 500ms simulated network delay
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Library Books'), findsOneWidget);
      expect(find.byType(BookCard), findsWidgets);
    });

    testWidgets('filters list via search bar (debounce 500ms)', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Clean');
      // Wait past debounce + network delay
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // At least one known book matches 'Clean' in mock data
      expect(find.text('Clean Code'), findsOneWidget);
    });
  });
}
