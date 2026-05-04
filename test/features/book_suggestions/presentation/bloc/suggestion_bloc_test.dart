import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/book_suggestions/domain/repositories/suggestion_repository.dart';
import 'package:lib_42_flutter/features/book_suggestions/presentation/bloc/suggestion_bloc.dart';
import 'package:lib_42_flutter/features/book_suggestions/presentation/bloc/suggestion_event.dart';
import 'package:lib_42_flutter/features/book_suggestions/presentation/bloc/suggestion_state.dart';

import '../../../../support/fake_suggestion_repository.dart';

void main() {
  group('SuggestionBloc', () {
    blocTest<SuggestionBloc, SuggestionState>(
      'load: emits [Loading, Loaded] with active period and mine',
      build: () {
        final repo = FakeSuggestionRepository()
          ..activePeriod = makePeriod()
          ..mine = [makeSuggestion(id: 'a'), makeSuggestion(id: 'b')];
        return SuggestionBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const SuggestionsRequested()),
      expect: () => [
        isA<SuggestionLoading>(),
        isA<SuggestionLoaded>()
            .having((s) => s.activePeriod?.name, 'period.name', '2024 Q1')
            .having((s) => s.mySuggestions.length, 'mine count', 2),
      ],
    );

    blocTest<SuggestionBloc, SuggestionState>(
      'load: emits [Loading, Error] when repository throws',
      build: () {
        final repo = FakeSuggestionRepository()..error = Exception('boom');
        return SuggestionBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const SuggestionsRequested()),
      expect: () => [isA<SuggestionLoading>(), isA<SuggestionError>()],
    );

    blocTest<SuggestionBloc, SuggestionState>(
      'submit: prepends new suggestion and reports success',
      build: () {
        final repo = FakeSuggestionRepository()
          ..submitResult = makeSuggestion(id: 'new', suggestedTitle: 'N');
        return SuggestionBloc(repository: repo);
      },
      seed: () => SuggestionLoaded(
        activePeriod: makePeriod(),
        mySuggestions: [makeSuggestion(id: 'old')],
      ),
      act: (bloc) => bloc.add(const SuggestionSubmitted(
        suggestedTitle: 'N',
        suggestedAuthor: 'A',
      )),
      expect: () => [
        isA<SuggestionLoaded>().having(
          (s) => s.actionStatus,
          'inProgress',
          SuggestionActionStatus.inProgress,
        ),
        isA<SuggestionLoaded>()
            .having((s) => s.mySuggestions.first.id, 'first.id', 'new')
            .having((s) => s.mySuggestions.length, 'count', 2)
            .having((s) => s.actionStatus, 'success',
                SuggestionActionStatus.success),
      ],
    );

    blocTest<SuggestionBloc, SuggestionState>(
      'submit: surfaces SuggestionException message',
      build: () {
        final repo = FakeSuggestionRepository()
          ..error = const SuggestionException(
            'duplicate_suggestion',
            '동일한 도서를 이미 추천했습니다.',
          );
        return SuggestionBloc(repository: repo);
      },
      seed: () => SuggestionLoaded(
        activePeriod: makePeriod(),
        mySuggestions: const [],
      ),
      act: (bloc) => bloc.add(const SuggestionSubmitted(
        suggestedTitle: 'X',
        suggestedAuthor: 'Y',
      )),
      expect: () => [
        isA<SuggestionLoaded>().having((s) => s.actionStatus, 'inProgress',
            SuggestionActionStatus.inProgress),
        isA<SuggestionLoaded>()
            .having((s) => s.actionStatus, 'failure',
                SuggestionActionStatus.failure)
            .having((s) => s.actionMessage, 'message', '동일한 도서를 이미 추천했습니다.'),
      ],
    );
  });
}
