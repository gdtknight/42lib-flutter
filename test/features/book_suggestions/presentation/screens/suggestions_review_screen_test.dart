import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/book_suggestions/data/models/book_suggestion.dart';
import 'package:lib_42_flutter/features/book_suggestions/presentation/screens/suggestions_review_screen.dart';

import '../../../../support/fake_admin_suggestion_repository.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeAdminSuggestionRepository repo,
) async {
  await tester.pumpWidget(MaterialApp(
    home: SuggestionsReviewScreen(repository: repo),
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
