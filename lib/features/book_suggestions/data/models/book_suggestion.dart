import 'package:equatable/equatable.dart';

import 'collection_period.dart';

enum SuggestionStatus { submitted, approved, rejected, underReview }

SuggestionStatus _parseSuggestionStatus(String raw) {
  switch (raw) {
    case 'submitted':
      return SuggestionStatus.submitted;
    case 'approved':
      return SuggestionStatus.approved;
    case 'rejected':
      return SuggestionStatus.rejected;
    case 'under_review':
      return SuggestionStatus.underReview;
    default:
      throw ArgumentError('Unknown suggestion status: $raw');
  }
}

/// CollectionPeriod summary embedded in suggestion responses.
class SuggestionPeriodSummary extends Equatable {
  final String id;
  final String name;
  final PeriodStatus? status;
  final DateTime endDate;

  const SuggestionPeriodSummary({
    required this.id,
    required this.name,
    this.status,
    required this.endDate,
  });

  factory SuggestionPeriodSummary.fromJson(Map<String, dynamic> json) {
    return SuggestionPeriodSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] is String
          ? CollectionPeriod.fromJson({
              'id': json['id'] as String,
              'name': json['name'] as String,
              'startDate':
                  json['startDate'] as String? ?? '1970-01-01T00:00:00.000Z',
              'endDate': json['endDate'] as String,
              'status': json['status'] as String,
            }).status
          : null,
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, status, endDate];
}

class BookSuggestion extends Equatable {
  final String id;
  final String studentId;
  final String suggestedTitle;
  final String suggestedAuthor;
  final String? reason;
  final String collectionPeriodId;
  final SuggestionStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? adminNotes;
  final SuggestionPeriodSummary? collectionPeriod;

  const BookSuggestion({
    required this.id,
    required this.studentId,
    required this.suggestedTitle,
    required this.suggestedAuthor,
    this.reason,
    required this.collectionPeriodId,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.adminNotes,
    this.collectionPeriod,
  });

  factory BookSuggestion.fromJson(Map<String, dynamic> json) {
    return BookSuggestion(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      suggestedTitle: json['suggestedTitle'] as String,
      suggestedAuthor: json['suggestedAuthor'] as String,
      reason: json['reason'] as String?,
      collectionPeriodId: json['collectionPeriodId'] as String,
      status: _parseSuggestionStatus(json['status'] as String),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
      reviewedBy: json['reviewedBy'] as String?,
      adminNotes: json['adminNotes'] as String?,
      collectionPeriod: json['collectionPeriod'] is Map<String, dynamic>
          ? SuggestionPeriodSummary.fromJson(
              json['collectionPeriod'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  bool get isSubmitted => status == SuggestionStatus.submitted;
  bool get isApproved => status == SuggestionStatus.approved;
  bool get isRejected => status == SuggestionStatus.rejected;
  bool get isUnderReview => status == SuggestionStatus.underReview;

  @override
  List<Object?> get props => [
        id,
        studentId,
        suggestedTitle,
        suggestedAuthor,
        reason,
        collectionPeriodId,
        status,
        submittedAt,
      ];
}
