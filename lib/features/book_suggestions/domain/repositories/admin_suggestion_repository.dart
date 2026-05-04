import '../../data/models/book_suggestion.dart';
import '../../data/models/collection_period.dart';
import '../../data/models/grouped_suggestion.dart';

class AdminSuggestionException implements Exception {
  final String code;
  final String message;
  const AdminSuggestionException(this.code, this.message);

  @override
  String toString() => 'AdminSuggestionException($code): $message';
}

abstract class AdminSuggestionRepository {
  Future<List<GroupedSuggestion>> fetchGrouped({String? periodId});

  /// Update a single suggestion record.
  Future<BookSuggestion> review(
    String suggestionId, {
    required SuggestionStatus status,
    String? adminNotes,
  });

  Future<CollectionPeriod> createPeriod({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    PeriodStatus status = PeriodStatus.upcoming,
  });
}
