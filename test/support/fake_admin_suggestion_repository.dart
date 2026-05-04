import 'package:lib_42_flutter/features/book_suggestions/data/models/book_suggestion.dart';
import 'package:lib_42_flutter/features/book_suggestions/data/models/collection_period.dart';
import 'package:lib_42_flutter/features/book_suggestions/data/models/grouped_suggestion.dart';
import 'package:lib_42_flutter/features/book_suggestions/domain/repositories/admin_suggestion_repository.dart';

import 'fake_suggestion_repository.dart' show makePeriod, makeSuggestion;

export 'fake_suggestion_repository.dart' show makePeriod, makeSuggestion;

class FakeAdminSuggestionRepository implements AdminSuggestionRepository {
  List<GroupedSuggestion> grouped = [];
  BookSuggestion? reviewResult;
  CollectionPeriod? createPeriodResult;
  Exception? error;

  int fetchCalls = 0;
  int reviewCalls = 0;
  int createPeriodCalls = 0;

  @override
  Future<List<GroupedSuggestion>> fetchGrouped({String? periodId}) async {
    fetchCalls++;
    if (error != null) throw error!;
    return grouped;
  }

  @override
  Future<BookSuggestion> review(
    String suggestionId, {
    required SuggestionStatus status,
    String? adminNotes,
  }) async {
    reviewCalls++;
    if (error != null) throw error!;
    return reviewResult ??
        makeSuggestion(id: suggestionId, status: status, adminNotes: adminNotes);
  }

  @override
  Future<CollectionPeriod> createPeriod({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    PeriodStatus status = PeriodStatus.upcoming,
  }) async {
    createPeriodCalls++;
    if (error != null) throw error!;
    return createPeriodResult ??
        CollectionPeriod(
          id: 'np-${createPeriodCalls}',
          name: name,
          startDate: startDate,
          endDate: endDate,
          status: status,
        );
  }
}

GroupedSuggestion makeGroup({
  String title = '책1',
  String author = '저자1',
  String periodId = 'p1',
  int requesterCount = 2,
  Map<SuggestionStatus, int>? statuses,
  List<BookSuggestion>? items,
}) {
  return GroupedSuggestion(
    suggestedTitle: title,
    suggestedAuthor: author,
    collectionPeriodId: periodId,
    requesterCount: requesterCount,
    statuses: statuses ?? {SuggestionStatus.submitted: requesterCount},
    latestSubmittedAt: DateTime(2024, 2, 1),
    items: items ??
        List.generate(
          requesterCount,
          (i) => makeSuggestion(
            id: 'sg-$i',
            studentId: 'stu-$i',
            suggestedTitle: title,
            suggestedAuthor: author,
            collectionPeriodId: periodId,
          ),
        ),
  );
}
