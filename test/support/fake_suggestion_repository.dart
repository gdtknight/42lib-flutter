import 'package:lib_42_flutter/features/book_suggestions/data/models/book_suggestion.dart';
import 'package:lib_42_flutter/features/book_suggestions/data/models/collection_period.dart';
import 'package:lib_42_flutter/features/book_suggestions/domain/repositories/suggestion_repository.dart';

class FakeSuggestionRepository implements SuggestionRepository {
  CollectionPeriod? activePeriod;
  List<BookSuggestion> mine = [];
  BookSuggestion? submitResult;
  Exception? error;

  int submitCalls = 0;
  int fetchMineCalls = 0;

  @override
  Future<CollectionPeriod?> fetchActivePeriod() async {
    if (error != null) throw error!;
    return activePeriod;
  }

  @override
  Future<List<BookSuggestion>> fetchMine() async {
    fetchMineCalls++;
    if (error != null) throw error!;
    return mine;
  }

  @override
  Future<BookSuggestion> submit({
    required String suggestedTitle,
    required String suggestedAuthor,
    String? reason,
  }) async {
    submitCalls++;
    if (error != null) throw error!;
    return submitResult ??
        makeSuggestion(suggestedTitle: suggestedTitle, suggestedAuthor: suggestedAuthor);
  }
}

CollectionPeriod makePeriod({
  String id = 'p1',
  String name = '2024 Q1',
  PeriodStatus status = PeriodStatus.active,
}) {
  return CollectionPeriod(
    id: id,
    name: name,
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 3, 31),
    status: status,
  );
}

BookSuggestion makeSuggestion({
  String id = 'sg-1',
  String studentId = 'stu-1',
  String suggestedTitle = '추천 도서',
  String suggestedAuthor = '저자',
  String? reason,
  SuggestionStatus status = SuggestionStatus.submitted,
  String collectionPeriodId = 'p1',
  String? adminNotes,
}) {
  return BookSuggestion(
    id: id,
    studentId: studentId,
    suggestedTitle: suggestedTitle,
    suggestedAuthor: suggestedAuthor,
    reason: reason,
    collectionPeriodId: collectionPeriodId,
    status: status,
    submittedAt: DateTime(2024, 2, 1),
    adminNotes: adminNotes,
  );
}
