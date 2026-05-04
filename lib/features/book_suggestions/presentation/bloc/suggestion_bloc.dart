import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/suggestion_repository.dart';
import 'suggestion_event.dart';
import 'suggestion_state.dart';

class SuggestionBloc extends Bloc<SuggestionEvent, SuggestionState> {
  final SuggestionRepository repository;

  SuggestionBloc({required this.repository})
      : super(const SuggestionInitial()) {
    on<SuggestionsRequested>(_onLoad);
    on<SuggestionSubmitted>(_onSubmit);
  }

  Future<void> _onLoad(
    SuggestionsRequested event,
    Emitter<SuggestionState> emit,
  ) async {
    emit(const SuggestionLoading());
    try {
      final period = await repository.fetchActivePeriod();
      final mine = await repository.fetchMine();
      emit(SuggestionLoaded(activePeriod: period, mySuggestions: mine));
    } on SuggestionException catch (e) {
      emit(SuggestionError(e.message));
    } catch (e) {
      emit(SuggestionError(e.toString()));
    }
  }

  Future<void> _onSubmit(
    SuggestionSubmitted event,
    Emitter<SuggestionState> emit,
  ) async {
    final current = state;
    if (current is! SuggestionLoaded) return;
    emit(current.copyWith(actionStatus: SuggestionActionStatus.inProgress));
    try {
      final created = await repository.submit(
        suggestedTitle: event.suggestedTitle,
        suggestedAuthor: event.suggestedAuthor,
        reason: event.reason,
      );
      emit(current.copyWith(
        mySuggestions: [created, ...current.mySuggestions],
        actionStatus: SuggestionActionStatus.success,
        actionMessage: '추천이 제출되었습니다.',
      ));
    } on SuggestionException catch (e) {
      emit(current.copyWith(
        actionStatus: SuggestionActionStatus.failure,
        actionMessage: e.message,
      ));
    } catch (e) {
      emit(current.copyWith(
        actionStatus: SuggestionActionStatus.failure,
        actionMessage: e.toString(),
      ));
    }
  }
}
