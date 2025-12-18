import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lib_42_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Book Browsing Flow Integration Test', () {
    testWidgets('Complete book browsing and search flow',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Verify home screen loads
      expect(find.text('도서 목록'), findsOneWidget);

      // 2. Wait for books to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 3. Verify book cards are displayed
      expect(find.byType(Card), findsWidgets);

      // 4. Test search functionality
      await tester.enterText(find.byType(TextField), 'Clean Code');
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // 5. Verify search results
      expect(find.text('Clean Code'), findsWidgets);

      // 6. Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // 7. Test category filter
      await tester.tap(find.text('프로그래밍'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 8. Verify filtered results
      expect(find.text('Programming'), findsWidgets);

      // 9. Tap on a book card
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      // 10. Verify book detail screen
      expect(find.text('책 상세'), findsOneWidget);
      expect(find.text('저자'), findsOneWidget);
      expect(find.text('카테고리'), findsOneWidget);
      expect(find.text('대여 가능 여부'), findsOneWidget);

      // 11. Go back to home
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 12. Verify back at home screen
      expect(find.text('도서 목록'), findsOneWidget);

      // 13. Test scroll to load more
      await tester.drag(find.byType(Card).last, const Offset(0, -500));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 14. Verify more books loaded
      expect(find.byType(Card), findsWidgets);

      // 15. Test pull to refresh
      await tester.drag(find.text('도서 목록'), const Offset(0, 300));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 16. Verify books refreshed
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Search with no results', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Search for non-existent book
      await tester.enterText(find.byType(TextField), 'NonExistentBook12345');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify empty state message
      expect(find.text('검색 결과가 없습니다'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('Filter shows only books in selected category',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for initial load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Select Design category
      await tester.tap(find.text('디자인'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify only design books are shown
      expect(find.text('Design'), findsWidgets);
      expect(find.text('Programming'), findsNothing);

      // Select all categories
      await tester.tap(find.text('전체'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify all books are shown
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Book availability status is displayed correctly',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for books to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap on first book
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      // Verify availability information is shown
      expect(find.textContaining('대여 가능'), findsOneWidget);
      expect(find.textContaining('/'), findsOneWidget); // Shows X/Y format
    });

    testWidgets('Navigate between multiple books', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for books to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Get first book title
      final firstBookTitle =
          (tester.widget(find.byType(Text).first) as Text).data;

      // Tap first book
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      // Verify on detail page
      expect(find.text(firstBookTitle!), findsOneWidget);

      // Go back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Tap second book
      await tester.tap(find.byType(Card).at(1));
      await tester.pumpAndSettle();

      // Verify on different detail page
      expect(find.text(firstBookTitle), findsNothing);
      expect(find.text('책 상세'), findsOneWidget);
    });
  });
}
