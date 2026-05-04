import 'package:equatable/equatable.dart';

import '../../data/models/book_suggestion.dart';
import '../../data/models/collection_period.dart';

abstract class AdminSuggestionsEvent extends Equatable {
  const AdminSuggestionsEvent();

  @override
  List<Object?> get props => [];
}

class AdminSuggestionsRequested extends AdminSuggestionsEvent {
  final String? periodId;
  const AdminSuggestionsRequested({this.periodId});

  @override
  List<Object?> get props => [periodId];
}

class AdminSuggestionReviewed extends AdminSuggestionsEvent {
  final String suggestionId;
  final SuggestionStatus status;
  final String? adminNotes;

  const AdminSuggestionReviewed({
    required this.suggestionId,
    required this.status,
    this.adminNotes,
  });

  @override
  List<Object?> get props => [suggestionId, status, adminNotes];
}

class AdminPeriodCreated extends AdminSuggestionsEvent {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final PeriodStatus status;

  const AdminPeriodCreated({
    required this.name,
    required this.startDate,
    required this.endDate,
    this.status = PeriodStatus.upcoming,
  });

  @override
  List<Object?> get props => [name, startDate, endDate, status];
}
