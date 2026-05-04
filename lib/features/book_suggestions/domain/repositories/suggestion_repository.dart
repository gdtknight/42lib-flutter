import '../../data/models/book_suggestion.dart';
import '../../data/models/collection_period.dart';

class SuggestionException implements Exception {
  final String
      code; // no_active_period | duplicate_suggestion | network | unauthorized | unknown
  final String message;
  const SuggestionException(this.code, this.message);

  @override
  String toString() => 'SuggestionException($code): $message';
}

abstract class SuggestionRepository {
  Future<CollectionPeriod?> fetchActivePeriod();

  Future<BookSuggestion> submit({
    required String suggestedTitle,
    required String suggestedAuthor,
    String? reason,
  });

  Future<List<BookSuggestion>> fetchMine();
}
