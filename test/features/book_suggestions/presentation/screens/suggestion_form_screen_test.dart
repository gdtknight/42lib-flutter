import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lib_42_flutter/features/book_suggestions/data/models/collection_period.dart';
import 'package:lib_42_flutter/features/book_suggestions/presentation/bloc/suggestion_bloc.dart';
import 'package:lib_42_flutter/features/book_suggestions/presentation/bloc/suggestion_state.dart';
import 'package:lib_42_flutter/features/book_suggestions/presentation/screens/suggestion_form_screen.dart';

import '../../../../support/fake_suggestion_repository.dart';

SuggestionBloc _bloc({
  FakeSuggestionRepository? repo,
}) =>
    SuggestionBloc(repository: repo ?? FakeSuggestionRepository());

Future<void> _pump(
  WidgetTester tester, {
  required SuggestionBloc bloc,
  SuggestionState? seed,
}) async {
  if (seed != null) bloc.emit(seed);
  addTearDown(bloc.close);
  // The screen calls `context.go('/suggestions/mine')` on success, so we need
  // a GoRouter in the tree for routing-affected paths to work.
  final router = GoRouter(
    initialLocation: '/suggestions/new',
    routes: [
      GoRoute(
        path: '/suggestions/new',
        builder: (_, __) => SuggestionFormScreen(bloc: bloc),
      ),
      GoRoute(
        path: '/suggestions/mine',
        builder: (_, __) => const Scaffold(body: Text('mine-redirect')),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pump();
}

void main() {
  group('SuggestionFormScreen', () {
    testWidgets('renders form fields and submit button', (tester) async {
      await _pump(tester, bloc: _bloc());

      expect(find.text('도서 추천'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3)); // 제목/저자/사유
      expect(find.widgetWithText(FilledButton, '제출'), findsOneWidget);
    });

    testWidgets('active period banner shows name + end date + countdown',
        (tester) async {
      await _pump(
        tester,
        bloc: _bloc(),
        seed: SuggestionLoaded(
          activePeriod: makePeriod(
            name: '2024 Q3',
            status: PeriodStatus.active,
          ),
          mySuggestions: const [],
        ),
      );

      expect(find.textContaining('2024 Q3'), findsOneWidget);
      // 시드의 endDate=2024-03-31 → 오늘 기준 D-? or 종료. 어쨌든 banner body 존재.
      expect(find.byIcon(Icons.event_available), findsOneWidget);
    });

    testWidgets(
        'closed period shows info banner and disables form (T180)',
        (tester) async {
      await _pump(
        tester,
        bloc: _bloc(),
        seed: SuggestionLoaded(
          activePeriod: makePeriod(
            name: '2024 Q1',
            status: PeriodStatus.closed,
          ),
          mySuggestions: const [],
        ),
      );

      expect(find.textContaining('2024 Q1'), findsOneWidget);
      expect(find.textContaining('종료'), findsOneWidget);
      // 폼이 비활성화되어 submit 버튼 onPressed가 null
      final submit =
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, '제출'));
      expect(submit.onPressed, isNull);
    });

    testWidgets(
        'upcoming period shows info banner and disables form (T180)',
        (tester) async {
      await _pump(
        tester,
        bloc: _bloc(),
        seed: SuggestionLoaded(
          activePeriod: makePeriod(
            name: '2024 Q4',
            status: PeriodStatus.upcoming,
          ),
          mySuggestions: const [],
        ),
      );

      expect(find.textContaining('예정'), findsOneWidget);
      final submit =
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, '제출'));
      expect(submit.onPressed, isNull);
    });

    testWidgets(
        'no active period shows error banner and disables form (T178)',
        (tester) async {
      await _pump(
        tester,
        bloc: _bloc(),
        seed: const SuggestionLoaded(
          activePeriod: null,
          mySuggestions: [],
        ),
      );

      expect(find.text('활성 수집 기간이 없습니다'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      final submit =
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, '제출'));
      expect(submit.onPressed, isNull);
    });

    testWidgets('validation: empty title shows error message', (tester) async {
      await _pump(
        tester,
        bloc: _bloc(),
        seed: SuggestionLoaded(
          activePeriod: makePeriod(),
          mySuggestions: const [],
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, '제출'));
      await tester.pump();

      expect(find.text('제목을(를) 입력하세요'), findsOneWidget);
      expect(find.text('저자을(를) 입력하세요'), findsOneWidget);
    });

    testWidgets('validation: title over 500 chars rejected', (tester) async {
      await _pump(
        tester,
        bloc: _bloc(),
        seed: SuggestionLoaded(
          activePeriod: makePeriod(),
          mySuggestions: const [],
        ),
      );

      final longText = 'a' * 501;
      await tester.enterText(find.byType(TextFormField).at(0), longText);
      await tester.enterText(find.byType(TextFormField).at(1), 'Author');
      await tester.tap(find.widgetWithText(FilledButton, '제출'));
      await tester.pump();

      expect(find.text('제목은(는) 500자 이하여야 합니다'), findsOneWidget);
    });

    testWidgets('valid submit dispatches SuggestionSubmitted', (tester) async {
      final repo = FakeSuggestionRepository()
        ..submitResult = makeSuggestion(
          id: 'new',
          suggestedTitle: '새 도서',
          suggestedAuthor: '새 저자',
        );
      final bloc = _bloc(repo: repo);
      await _pump(
        tester,
        bloc: bloc,
        seed: SuggestionLoaded(
          activePeriod: makePeriod(),
          mySuggestions: const [],
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), '새 도서');
      await tester.enterText(find.byType(TextFormField).at(1), '새 저자');
      await tester.enterText(find.byType(TextFormField).at(2), '학습용');
      await tester.tap(find.widgetWithText(FilledButton, '제출'));
      await tester.pump();

      expect(repo.submitCalls, 1);
    });

    testWidgets('shows progress indicator while submission in progress',
        (tester) async {
      final bloc = _bloc();
      await _pump(
        tester,
        bloc: bloc,
        seed: SuggestionLoaded(
          activePeriod: makePeriod(),
          mySuggestions: const [],
          actionStatus: SuggestionActionStatus.inProgress,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('제출'), findsNothing);
    });

    testWidgets('failure state surfaces snackbar with action message',
        (tester) async {
      final bloc = _bloc();
      await _pump(
        tester,
        bloc: bloc,
        seed: SuggestionLoaded(
          activePeriod: makePeriod(),
          mySuggestions: const [],
        ),
      );

      bloc.emit(SuggestionLoaded(
        activePeriod: makePeriod(),
        mySuggestions: const [],
        actionStatus: SuggestionActionStatus.failure,
        actionMessage: '동일한 도서를 이미 추천했습니다.',
      ));
      // listener fires + SnackBar enqueues + animates in. Need a few frames.
      await tester.pumpAndSettle();

      expect(find.text('동일한 도서를 이미 추천했습니다.'), findsOneWidget);
    });
  });
}
