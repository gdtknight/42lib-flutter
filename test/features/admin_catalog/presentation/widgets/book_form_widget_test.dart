import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/admin_catalog/domain/repositories/admin_book_repository.dart';
import 'package:lib_42_flutter/features/admin_catalog/presentation/widgets/book_form_widget.dart';

import '../../../../support/fake_admin_book_repository.dart';

Future<void> _pumpForm(
  WidgetTester tester, {
  required void Function(AdminBookPayload) onSubmit,
}) async {
  // Force a tall surface so the form Column doesn't overflow off-screen.
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BookFormWidget(onSubmit: onSubmit, submitLabel: '저장'),
        ),
      ),
    ),
  );
}

void main() {
  group('BookFormWidget (T066/T085/T091)', () {
    testWidgets('blocks submit when required fields are empty',
        (tester) async {
      AdminBookPayload? captured;
      await _pumpForm(tester, onSubmit: (p) => captured = p);

      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pump();

      expect(find.text('제목을(를) 입력하세요'), findsOneWidget);
      expect(find.text('저자을(를) 입력하세요'), findsOneWidget);
      expect(find.text('카테고리을(를) 입력하세요'), findsOneWidget);
      expect(captured, isNull);
    });

    testWidgets('rejects ISBN with wrong length', (tester) async {
      AdminBookPayload? captured;
      await _pumpForm(tester, onSubmit: (p) => captured = p);

      await tester.enterText(
          find.widgetWithText(TextFormField, '제목 *'), '책 제목');
      await tester.enterText(
          find.widgetWithText(TextFormField, '저자 *'), '작가');
      await tester.enterText(
          find.widgetWithText(TextFormField, '카테고리 *'), 'Tech');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'ISBN'), '12345');

      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pump();

      expect(find.text('ISBN은 10자리 또는 13자리 숫자여야 합니다'), findsOneWidget);
      expect(captured, isNull);
    });

    testWidgets('rejects available > quantity', (tester) async {
      AdminBookPayload? captured;
      await _pumpForm(tester, onSubmit: (p) => captured = p);

      await tester.enterText(
          find.widgetWithText(TextFormField, '제목 *'), '책');
      await tester.enterText(
          find.widgetWithText(TextFormField, '저자 *'), '저자');
      await tester.enterText(
          find.widgetWithText(TextFormField, '카테고리 *'), 'Cat');
      // Default quantity=1, override available to 5
      await tester.enterText(
          find.widgetWithText(TextFormField, '대출 가능 수량 *'), '5');

      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pump();

      expect(
        find.text('대출 가능 수량은 총 수량(1) 이하여야 합니다'),
        findsOneWidget,
      );
      expect(captured, isNull);
    });

    testWidgets('submits valid payload', (tester) async {
      AdminBookPayload? captured;
      await _pumpForm(tester, onSubmit: (p) => captured = p);

      await tester.enterText(
          find.widgetWithText(TextFormField, '제목 *'), 'Clean Code');
      await tester.enterText(
          find.widgetWithText(TextFormField, '저자 *'), 'Robert');
      await tester.enterText(
          find.widgetWithText(TextFormField, '카테고리 *'), 'Programming');
      await tester.enterText(
          find.widgetWithText(TextFormField, '총 수량 *'), '3');
      await tester.enterText(
          find.widgetWithText(TextFormField, '대출 가능 수량 *'), '3');

      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!.title, 'Clean Code');
      expect(captured!.quantity, 3);
      expect(captured!.availableQuantity, 3);
      expect(captured!.isbn, isNull);
    });

    testWidgets('prefills fields when editing existing book', (tester) async {
      final book = makeAdminBook(
        id: 'x',
        title: '기존',
        author: '원저자',
        category: 'Cat',
        quantity: 5,
        availableQuantity: 2,
      );
      AdminBookPayload? captured;
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: BookFormWidget(
                initial: book,
                onSubmit: (p) => captured = p,
              ),
            ),
          ),
        ),
      );

      expect(find.text('기존'), findsOneWidget);
      expect(find.text('원저자'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!.title, '기존');
      expect(captured!.quantity, 5);
    });
  });
}
