import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/book_suggestions/data/models/book_suggestion.dart';
import 'package:lib_42_flutter/features/book_suggestions/data/models/collection_period.dart';
import 'package:lib_42_flutter/features/book_suggestions/domain/repositories/admin_suggestion_repository.dart';
import 'package:lib_42_flutter/features/book_suggestions/presentation/bloc/admin_suggestions_bloc.dart';
import 'package:lib_42_flutter/features/book_suggestions/presentation/bloc/admin_suggestions_event.dart';
import 'package:lib_42_flutter/features/book_suggestions/presentation/bloc/admin_suggestions_state.dart';

import '../../../../support/fake_admin_suggestion_repository.dart';

void main() {
  group('AdminSuggestionsBloc', () {
    blocTest<AdminSuggestionsBloc, AdminSuggestionsState>(
      'load: emits [Loading, Loaded] with grouped suggestions',
      build: () {
        final repo = FakeAdminSuggestionRepository()
          ..grouped = [makeGroup(title: 'A'), makeGroup(title: 'B')];
        return AdminSuggestionsBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const AdminSuggestionsRequested()),
      expect: () => [
        isA<AdminSuggestionsLoading>(),
        isA<AdminSuggestionsLoaded>().having(
          (s) => s.groups.map((g) => g.suggestedTitle).toList(),
          'titles',
          ['A', 'B'],
        ),
      ],
    );

    blocTest<AdminSuggestionsBloc, AdminSuggestionsState>(
      'load: emits Error when repo throws',
      build: () {
        final repo = FakeAdminSuggestionRepository()
          ..error = const AdminSuggestionException('x', '에러');
        return AdminSuggestionsBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const AdminSuggestionsRequested()),
      expect: () => [
        isA<AdminSuggestionsLoading>(),
        isA<AdminSuggestionsError>(),
      ],
    );

    blocTest<AdminSuggestionsBloc, AdminSuggestionsState>(
      'review: replaces matching item and recomputes statuses',
      build: () {
        final group = makeGroup(
          title: 'Book',
          requesterCount: 2,
          statuses: {SuggestionStatus.submitted: 2},
          items: [
            makeSuggestion(id: 'a', status: SuggestionStatus.submitted),
            makeSuggestion(id: 'b', status: SuggestionStatus.submitted),
          ],
        );
        final repo = FakeAdminSuggestionRepository()
          ..reviewResult = makeSuggestion(
            id: 'a',
            status: SuggestionStatus.approved,
            adminNotes: '구매 예정',
          );
        return AdminSuggestionsBloc(repository: repo)
          ..emit(AdminSuggestionsLoaded(groups: [group]));
      },
      act: (bloc) => bloc.add(const AdminSuggestionReviewed(
        suggestionId: 'a',
        status: SuggestionStatus.approved,
        adminNotes: '구매 예정',
      )),
      expect: () => [
        isA<AdminSuggestionsLoaded>().having(
          (s) => s.actionStatus,
          'inProgress',
          AdminSuggestionsActionStatus.inProgress,
        ),
        isA<AdminSuggestionsLoaded>()
            .having((s) => s.actionStatus, 'success',
                AdminSuggestionsActionStatus.success)
            .having(
              (s) => s.groups.first.statuses,
              'recomputed',
              {
                SuggestionStatus.submitted: 1,
                SuggestionStatus.approved: 1,
              },
            )
            .having(
              (s) => s.groups.first.items
                  .firstWhere((i) => i.id == 'a')
                  .status,
              'updated.status',
              SuggestionStatus.approved,
            ),
      ],
    );

    blocTest<AdminSuggestionsBloc, AdminSuggestionsState>(
      'review: surfaces failure with action message',
      build: () {
        final repo = FakeAdminSuggestionRepository()
          ..error = const AdminSuggestionException('x', '실패함');
        return AdminSuggestionsBloc(repository: repo)
          ..emit(AdminSuggestionsLoaded(groups: [makeGroup()]));
      },
      act: (bloc) => bloc.add(const AdminSuggestionReviewed(
        suggestionId: 'sg-0',
        status: SuggestionStatus.rejected,
      )),
      expect: () => [
        isA<AdminSuggestionsLoaded>().having((s) => s.actionStatus, 'inProgress',
            AdminSuggestionsActionStatus.inProgress),
        isA<AdminSuggestionsLoaded>()
            .having((s) => s.actionStatus, 'failure',
                AdminSuggestionsActionStatus.failure)
            .having((s) => s.actionMessage, 'message', contains('실패함')),
      ],
    );

    blocTest<AdminSuggestionsBloc, AdminSuggestionsState>(
      'createPeriod: triggers reload after success',
      build: () {
        final repo = FakeAdminSuggestionRepository()
          ..grouped = [makeGroup(title: 'After Reload')];
        return AdminSuggestionsBloc(repository: repo);
      },
      act: (bloc) => bloc.add(AdminPeriodCreated(
        name: 'Q3',
        startDate: DateTime(2024, 7, 1),
        endDate: DateTime(2024, 9, 30),
        status: PeriodStatus.active,
      )),
      expect: () => [
        isA<AdminSuggestionsLoading>(),
        isA<AdminSuggestionsLoaded>().having(
          (s) => s.groups.first.suggestedTitle,
          'reloaded title',
          'After Reload',
        ),
      ],
      verify: (_) {},
    );
  });
}
