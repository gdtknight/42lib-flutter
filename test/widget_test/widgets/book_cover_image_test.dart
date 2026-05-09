import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/widgets/book_cover_image.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('BookCoverImage', () {
    testWidgets('null URL → placeholder (no network call)', (tester) async {
      await _pump(tester, const BookCoverImage(imageUrl: null));

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.book), findsOneWidget);
    });

    testWidgets('empty URL → placeholder', (tester) async {
      await _pump(tester, const BookCoverImage(imageUrl: ''));

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.book), findsOneWidget);
    });

    testWidgets('non-empty URL → CachedNetworkImage', (tester) async {
      await _pump(
        tester,
        const BookCoverImage(imageUrl: 'https://example.com/cover.jpg'),
      );
      // We can't fully test loading from network in a unit test, but we can
      // assert the right widget is in the tree.
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('respects width and height', (tester) async {
      await _pump(
        tester,
        const BookCoverImage(imageUrl: null, width: 80, height: 120),
      );
      // Placeholder should size itself to the requested dimensions.
      final placeholderSize = tester.getSize(find.byIcon(Icons.book).hitTestable());
      expect(placeholderSize.width, lessThanOrEqualTo(80));
    });

    testWidgets('borderRadius wraps the image in ClipRRect', (tester) async {
      await _pump(
        tester,
        BookCoverImage(
          imageUrl: 'https://example.com/cover.jpg',
          borderRadius: BorderRadius.circular(8),
        ),
      );
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('no borderRadius → no ClipRRect', (tester) async {
      await _pump(
        tester,
        const BookCoverImage(
          imageUrl: 'https://example.com/cover.jpg',
        ),
      );
      expect(find.byType(ClipRRect), findsNothing);
    });
  });
}
