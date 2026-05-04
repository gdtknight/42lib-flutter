import 'package:equatable/equatable.dart';

abstract class SuggestionEvent extends Equatable {
  const SuggestionEvent();
  @override
  List<Object?> get props => [];
}

class SuggestionsRequested extends SuggestionEvent {
  const SuggestionsRequested();
}

class SuggestionSubmitted extends SuggestionEvent {
  final String suggestedTitle;
  final String suggestedAuthor;
  final String? reason;

  const SuggestionSubmitted({
    required this.suggestedTitle,
    required this.suggestedAuthor,
    this.reason,
  });

  @override
  List<Object?> get props => [suggestedTitle, suggestedAuthor, reason];
}
