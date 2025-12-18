import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ft_transcendence/models/book.dart';
import 'package:ft_transcendence/widgets/book_card.dart';

void main() {
  testWidgets('BookCard displays book information correctly',
      (WidgetTester tester) async {
    final book = Book(
      id: '123e4567-e89b-12d3-a456-426614174000',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      isbn: '9780132350884',
      category: 'Programming',
      description: 'A handbook of agile software craftsmanship',
      quantity: 5,
      availableQuantity: 3,
      coverImageUrl: 'https://example.com/cover.jpg',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookCard(book: book),
        ),
      ),
    );

    expect(find.text('Clean Code'), findsOneWidget);
    expect(find.text('Robert C. Martin'), findsOneWidget);
    expect(find.text('Programming'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('BookCard shows availability status when available',
      (WidgetTester tester) async {
    final book = Book(
      id: '123e4567-e89b-12d3-a456-426614174000',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      category: 'Programming',
      quantity: 5,
      availableQuantity: 3,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookCard(book: book),
        ),
      ),
    );

    expect(find.text('대여 가능 (3/5)'), findsOneWidget);
  });

  testWidgets('BookCard shows unavailable status when no copies available',
      (WidgetTester tester) async {
    final book = Book(
      id: '123e4567-e89b-12d3-a456-426614174000',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      category: 'Programming',
      quantity: 5,
      availableQuantity: 0,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookCard(book: book),
        ),
      ),
    );

    expect(find.text('대여 중 (0/5)'), findsOneWidget);
  });

  testWidgets('BookCard handles missing cover image gracefully',
      (WidgetTester tester) async {
    final book = Book(
      id: '123e4567-e89b-12d3-a456-426614174000',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      category: 'Programming',
      quantity: 5,
      availableQuantity: 3,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookCard(book: book),
        ),
      ),
    );

    expect(find.byIcon(Icons.book), findsOneWidget);
  });

  testWidgets('BookCard is tappable and triggers onTap callback',
      (WidgetTester tester) async {
    final book = Book(
      id: '123e4567-e89b-12d3-a456-426614174000',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      category: 'Programming',
      quantity: 5,
      availableQuantity: 3,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookCard(
            book: book,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(BookCard));
    await tester.pumpAndSettle();

    expect(tapped, true);
  });

  testWidgets('BookCard displays category badge',
      (WidgetTester tester) async {
    final book = Book(
      id: '123e4567-e89b-12d3-a456-426614174000',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      category: 'Programming',
      quantity: 5,
      availableQuantity: 3,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookCard(book: book),
        ),
      ),
    );

    expect(find.text('Programming'), findsOneWidget);
    expect(find.byType(Chip), findsOneWidget);
  });
}
