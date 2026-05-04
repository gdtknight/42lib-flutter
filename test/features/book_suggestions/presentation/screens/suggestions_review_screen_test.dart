import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/book_suggestions/data/models/book_suggestion.dart';
import 'package:lib_42_flutter/features/book_suggestions/presentation/screens/suggestions_review_screen.dart';

import '../../../../support/fake_admin_book_repository.dart';
import '../../../../support/fake_admin_suggestion_repository.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeAdminSuggestionRepository repo, {
  FakeAdminBookRepository? bookRepo,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: SuggestionsReviewScreen(
      repository: repo,
      bookRepository: bookRepo ?? FakeAdminBookRepository(),
    ),
  ));
  // Initial AdminSuggestionsRequested → AdminSuggestionsLoading → Loaded.
  await tester.pump();
  await tester.pump();
}

void main() {
  group('SuggestionsReviewScreen', () {
    testWidgets('renders empty state when no groups', (tester) async {
      final repo = FakeAdminSuggestionRepository()..grouped = [];
      await _pump(tester, repo);
      expect(find.text('활성 수집 기간에 제출된 추천이 없습니다.'), findsOneWidget);
    });

    testWidgets('renders group card with title, author, and counts',
        (tester) async {
      final repo = FakeAdminSuggestionRepository()
        ..grouped = [
          makeGroup(
            title: 'Effective Dart',
            author: 'Google',
            requesterCount: 3,
            statuses: const {
              SuggestionStatus.submitted: 2,
              SuggestionStatus.approved: 1,
            },
            items: [
              makeSuggestion(id: 'a', status: SuggestionStatus.submitted),
              makeSuggestion(id: 'b', status: SuggestionStatus.submitted),
              makeSuggestion(id: 'c', status: SuggestionStatus.approved),
            ],
          ),
        ];
      await _pump(tester, repo);

      expect(find.text('Effective Dart'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('추천 3명'), findsOneWidget);
      expect(find.textContaining('제출됨'), findsAtLeastNWidgets(1));
      expect(find.textContaining('승인'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows error state and retry button when load fails',
        (tester) async {
      final repo = FakeAdminSuggestionRepository()..error = Exception('네트워크 오류');
      await _pump(tester, repo);

      expect(find.textContaining('네트워크 오류'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '다시 시도'), findsOneWidget);
    });

    testWidgets('promote action calls AdminBookRepository.createBook (T196)',
        (tester) async {
      final repo = FakeAdminSuggestionRepository()
        ..grouped = [
          makeGroup(items: [
            makeSuggestion(
              id: 'a',
              suggestedTitle: '클린 아키텍처',
              suggestedAuthor: 'R. Martin',
              status: SuggestionStatus.approved,
            ),
          ]),
        ];
      final bookRepo = FakeAdminBookRepository();
      await _pump(tester, repo, bookRepo: bookRepo);

      await tester.tap(find.byTooltip('카탈로그에 등록'));
      await tester.pumpAndSettle();

      // Title and author should be prefilled.
      expect(find.widgetWithText(TextFormField, '클린 아키텍처'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'R. Martin'), findsOneWidget);

      // Fill required category (3rd TextFormField: title/author/category),
      // then submit. The submit button sits below the viewport in the
      // 800×600 test surface, so scroll it into view first.
      await tester.enterText(find.byType(TextFormField).at(2), 'Programming');
      await tester.pump();
      final submit = find.widgetWithText(FilledButton, '카탈로그에 등록');
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit, warnIfMissed: false);
      await tester.pumpAndSettle();
      // Allow async createBook + dialog dismiss + snackbar.
      await tester.pump(const Duration(milliseconds: 50));

      expect(bookRepo.createCalls, 1);
    });

    testWidgets('approve action shows dialog with notes field', (tester) async {
      final repo = FakeAdminSuggestionRepository()
        ..grouped = [
          makeGroup(items: [
            makeSuggestion(id: 'a', status: SuggestionStatus.submitted),
            makeSuggestion(id: 'b', status: SuggestionStatus.submitted),
          ]),
        ];
      await _pump(tester, repo);

      // Tap the first approve icon button.
      final approveButtons = find.byTooltip('승인');
      expect(approveButtons, findsAtLeastNWidgets(1));
      await tester.tap(approveButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('추천 승인'), findsOneWidget);
      expect(find.text('관리자 메모 (선택)'), findsOneWidget);
      // Cancel to clean up.
      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();
    });
  });
}
