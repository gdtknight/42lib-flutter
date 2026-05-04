import 'package:equatable/equatable.dart';

import 'book_suggestion.dart';

/// Admin-side grouping: suggestions for the same (title, author, period)
/// collapsed together so the dashboard can show overall demand.
class GroupedSuggestion extends Equatable {
  final String suggestedTitle;
  final String suggestedAuthor;
  final String collectionPeriodId;
  final int requesterCount;
  final Map<SuggestionStatus, int> statuses;
  final DateTime latestSubmittedAt;
  final List<BookSuggestion> items;

  const GroupedSuggestion({
    required this.suggestedTitle,
    required this.suggestedAuthor,
    required this.collectionPeriodId,
    required this.requesterCount,
    required this.statuses,
    required this.latestSubmittedAt,
    required this.items,
  });

  factory GroupedSuggestion.fromJson(Map<String, dynamic> json) {
    final rawStatuses = json['statuses'] as Map<String, dynamic>? ?? const {};
    final statuses = <SuggestionStatus, int>{};
    rawStatuses.forEach((key, value) {
      switch (key) {
        case 'submitted':
          statuses[SuggestionStatus.submitted] = value as int;
          break;
        case 'approved':
          statuses[SuggestionStatus.approved] = value as int;
          break;
        case 'rejected':
          statuses[SuggestionStatus.rejected] = value as int;
          break;
        case 'under_review':
          statuses[SuggestionStatus.underReview] = value as int;
          break;
      }
    });

    final items = (json['items'] as List<dynamic>? ?? [])
        .map((j) => BookSuggestion.fromJson(j as Map<String, dynamic>))
        .toList();

    return GroupedSuggestion(
      suggestedTitle: json['suggestedTitle'] as String,
      suggestedAuthor: json['suggestedAuthor'] as String,
      collectionPeriodId: json['collectionPeriodId'] as String,
      requesterCount: json['requesterCount'] as int,
      statuses: statuses,
      latestSubmittedAt: DateTime.parse(json['latestSubmittedAt'] as String),
      items: items,
    );
  }

  /// Group key independent of internal ordering.
  String get groupKey =>
      '$suggestedTitle::$suggestedAuthor::$collectionPeriodId';

  GroupedSuggestion copyWith({
    int? requesterCount,
    Map<SuggestionStatus, int>? statuses,
    DateTime? latestSubmittedAt,
    List<BookSuggestion>? items,
  }) {
    return GroupedSuggestion(
      suggestedTitle: suggestedTitle,
      suggestedAuthor: suggestedAuthor,
      collectionPeriodId: collectionPeriodId,
      requesterCount: requesterCount ?? this.requesterCount,
      statuses: statuses ?? this.statuses,
      latestSubmittedAt: latestSubmittedAt ?? this.latestSubmittedAt,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
        suggestedTitle,
        suggestedAuthor,
        collectionPeriodId,
        requesterCount,
        statuses,
        latestSubmittedAt,
        items,
      ];
}
