import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/book_suggestion.dart';
import '../../data/models/grouped_suggestion.dart';
import '../../domain/repositories/admin_suggestion_repository.dart';
import 'admin_suggestions_event.dart';
import 'admin_suggestions_state.dart';

class AdminSuggestionsBloc
    extends Bloc<AdminSuggestionsEvent, AdminSuggestionsState> {
  final AdminSuggestionRepository repository;

  AdminSuggestionsBloc({required this.repository})
      : super(const AdminSuggestionsInitial()) {
    on<AdminSuggestionsRequested>(_onLoad);
    on<AdminSuggestionReviewed>(_onReview);
    on<AdminPeriodCreated>(_onCreatePeriod);
  }

  Future<void> _onLoad(
    AdminSuggestionsRequested event,
    Emitter<AdminSuggestionsState> emit,
  ) async {
    emit(const AdminSuggestionsLoading());
    try {
      final groups = await repository.fetchGrouped(periodId: event.periodId);
      emit(AdminSuggestionsLoaded(groups: groups));
    } catch (e) {
      emit(AdminSuggestionsError(_messageFor(e)));
    }
  }

  Future<void> _onReview(
    AdminSuggestionReviewed event,
    Emitter<AdminSuggestionsState> emit,
  ) async {
    final current = state;
    if (current is! AdminSuggestionsLoaded) return;
    emit(current.copyWith(
        actionStatus: AdminSuggestionsActionStatus.inProgress));
    try {
      final updated = await repository.review(
        event.suggestionId,
        status: event.status,
        adminNotes: event.adminNotes,
      );
      emit(current.copyWith(
        groups: _replaceItem(current.groups, updated),
        actionStatus: AdminSuggestionsActionStatus.success,
        actionMessage: '검토 결과가 저장되었습니다.',
      ));
    } catch (e) {
      emit(current.copyWith(
        actionStatus: AdminSuggestionsActionStatus.failure,
        actionMessage: _messageFor(e),
      ));
    }
  }

  Future<void> _onCreatePeriod(
    AdminPeriodCreated event,
    Emitter<AdminSuggestionsState> emit,
  ) async {
    final current = state;
    if (current is AdminSuggestionsLoaded) {
      emit(current.copyWith(
          actionStatus: AdminSuggestionsActionStatus.inProgress));
    }
    try {
      await repository.createPeriod(
        name: event.name,
        startDate: event.startDate,
        endDate: event.endDate,
        status: event.status,
      );
      // Reload — new active period archives previous active.
      add(const AdminSuggestionsRequested());
    } catch (e) {
      if (current is AdminSuggestionsLoaded) {
        emit(current.copyWith(
          actionStatus: AdminSuggestionsActionStatus.failure,
          actionMessage: _messageFor(e),
        ));
      } else {
        emit(AdminSuggestionsError(_messageFor(e)));
      }
    }
  }

  /// Returns a new list of groups with the updated suggestion replacing the
  /// matching item inside its group, with statuses recomputed.
  static List<GroupedSuggestion> _replaceItem(
    List<GroupedSuggestion> groups,
    BookSuggestion updated,
  ) {
    return groups.map((g) {
      final containsUpdated = g.items.any((s) => s.id == updated.id);
      if (!containsUpdated) return g;

      final newItems =
          g.items.map((s) => s.id == updated.id ? updated : s).toList();
      final newStatuses = <SuggestionStatus, int>{};
      for (final s in newItems) {
        newStatuses[s.status] = (newStatuses[s.status] ?? 0) + 1;
      }
      return g.copyWith(items: newItems, statuses: newStatuses);
    }).toList();
  }

  static String _messageFor(Object e) {
    if (e is Exception) {
      final msg = e.toString();
      return msg.startsWith('Exception: ') ? msg.substring(11) : msg;
    }
    return e.toString();
  }
}
