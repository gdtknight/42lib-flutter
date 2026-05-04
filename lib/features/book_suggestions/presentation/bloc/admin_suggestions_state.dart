import 'package:equatable/equatable.dart';

import '../../data/models/grouped_suggestion.dart';

enum AdminSuggestionsActionStatus { idle, inProgress, success, failure }

abstract class AdminSuggestionsState extends Equatable {
  const AdminSuggestionsState();

  @override
  List<Object?> get props => [];
}

class AdminSuggestionsInitial extends AdminSuggestionsState {
  const AdminSuggestionsInitial();
}

class AdminSuggestionsLoading extends AdminSuggestionsState {
  const AdminSuggestionsLoading();
}

class AdminSuggestionsLoaded extends AdminSuggestionsState {
  final List<GroupedSuggestion> groups;
  final AdminSuggestionsActionStatus actionStatus;
  final String? actionMessage;

  const AdminSuggestionsLoaded({
    required this.groups,
    this.actionStatus = AdminSuggestionsActionStatus.idle,
    this.actionMessage,
  });

  AdminSuggestionsLoaded copyWith({
    List<GroupedSuggestion>? groups,
    AdminSuggestionsActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return AdminSuggestionsLoaded(
      groups: groups ?? this.groups,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [groups, actionStatus, actionMessage];
}

class AdminSuggestionsError extends AdminSuggestionsState {
  final String message;
  const AdminSuggestionsError(this.message);

  @override
  List<Object?> get props => [message];
}
