import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/widgets/book_search_bar.dart';

void main() {
  testWidgets('BookSearchBar displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookSearchBar(
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('BookSearchBar accepts text input', (WidgetTester tester) async {
    String searchQuery = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookSearchBar(
            onChanged: (value) => searchQuery = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Clean Code');
    await tester.pump();

    expect(find.text('Clean Code'), findsOneWidget);
  });

  testWidgets('BookSearchBar debounces input', (WidgetTester tester) async {
    int callCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookSearchBar(
            onChanged: (_) => callCount++,
            debounceMilliseconds: 500,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'C');
    await tester.pump(const Duration(milliseconds: 100));
    
    await tester.enterText(find.byType(TextField), 'Cl');
    await tester.pump(const Duration(milliseconds: 100));
    
    await tester.enterText(find.byType(TextField), 'Clean');
    await tester.pump(const Duration(milliseconds: 600));

    // Should only call once after debounce period
    expect(callCount, 1);
  });

  testWidgets('BookSearchBar shows clear button when text is entered',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookSearchBar(
            onChanged: (_) {},
          ),
        ),
      ),
    );

    // Initially no clear button
    expect(find.byIcon(Icons.clear), findsNothing);

    // Enter text
    await tester.enterText(find.byType(TextField), 'Clean Code');
    await tester.pump();

    // Clear button should appear
    expect(find.byIcon(Icons.clear), findsOneWidget);
  });

  testWidgets('BookSearchBar clears text when clear button is tapped',
      (WidgetTester tester) async {
    String searchQuery = 'initial';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookSearchBar(
            onChanged: (value) => searchQuery = value,
          ),
        ),
      ),
    );

    // Enter text
    await tester.enterText(find.byType(TextField), 'Clean Code');
    await tester.pump();

    // Tap clear button
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(find.text('Clean Code'), findsNothing);
    expect(searchQuery, '');
  });

  testWidgets('BookSearchBar has placeholder text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookSearchBar(
            onChanged: (_) {},
            hintText: '책 제목, 저자로 검색',
          ),
        ),
      ),
    );

    expect(find.text('책 제목, 저자로 검색'), findsOneWidget);
  });

  testWidgets('BookSearchBar can be disabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookSearchBar(
            onChanged: (_) {},
            enabled: false,
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, false);
  });

  testWidgets('BookSearchBar applies custom styling', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookSearchBar(
            onChanged: (_) {},
            backgroundColor: Colors.blue,
            borderRadius: 16.0,
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(BookSearchBar),
        matching: find.byType(Container),
      ).first,
    );

    final decoration = container.decoration as BoxDecoration?;
    expect(decoration?.color, Colors.blue);
    expect(decoration?.borderRadius, BorderRadius.circular(16.0));
  });
}
