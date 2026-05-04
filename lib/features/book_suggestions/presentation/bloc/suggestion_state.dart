import 'package:equatable/equatable.dart';

import '../../data/models/book_suggestion.dart';
import '../../data/models/collection_period.dart';

enum SuggestionActionStatus { idle, inProgress, success, failure }

abstract class SuggestionState extends Equatable {
  const SuggestionState();
  @override
  List<Object?> get props => [];
}

class SuggestionInitial extends SuggestionState {
  const SuggestionInitial();
}

class SuggestionLoading extends SuggestionState {
  const SuggestionLoading();
}

class SuggestionLoaded extends SuggestionState {
  final CollectionPeriod? activePeriod;
  final List<BookSuggestion> mySuggestions;
  final SuggestionActionStatus actionStatus;
  final String? actionMessage;

  const SuggestionLoaded({
    required this.activePeriod,
    required this.mySuggestions,
    this.actionStatus = SuggestionActionStatus.idle,
    this.actionMessage,
  });

  SuggestionLoaded copyWith({
    CollectionPeriod? activePeriod,
    bool clearActivePeriod = false,
    List<BookSuggestion>? mySuggestions,
    SuggestionActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return SuggestionLoaded(
      activePeriod:
          clearActivePeriod ? null : (activePeriod ?? this.activePeriod),
      mySuggestions: mySuggestions ?? this.mySuggestions,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props =>
      [activePeriod, mySuggestions, actionStatus, actionMessage];
}

class SuggestionError extends SuggestionState {
  final String message;
  const SuggestionError(this.message);

  @override
  List<Object?> get props => [message];
}
