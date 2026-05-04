import 'package:dio/dio.dart';

import '../../../../services/storage/secure_storage_service.dart';
import '../../domain/repositories/suggestion_repository.dart';
import '../models/book_suggestion.dart';
import '../models/collection_period.dart';

class SuggestionRepositoryImpl implements SuggestionRepository {
  SuggestionRepositoryImpl({
    required String baseUrl,
    SecureStorageService? storage,
    Dio? httpClient,
  })  : _storage = storage ?? SecureStorageService(),
        _dio = httpClient ?? _build(baseUrl) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Student JWT for /suggestions; /collection-periods/active is public.
        final token = await _storage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  static Dio _build(String baseUrl) => Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
          validateStatus: (s) => s != null && s < 500,
        ),
      );

  final SecureStorageService _storage;
  final Dio _dio;

  @override
  Future<CollectionPeriod?> fetchActivePeriod() async {
    final res = await _dio.get<dynamic>('/v1/collection-periods/active');
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200 || res.data is! Map) {
      throw SuggestionException(
        'unknown',
        '활성 수집 기간 조회 실패 (${res.statusCode}).',
      );
    }
    final body = res.data as Map<String, dynamic>;
    return CollectionPeriod.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<BookSuggestion> submit({
    required String suggestedTitle,
    required String suggestedAuthor,
    String? reason,
  }) async {
    final res = await _dio.post<dynamic>(
      '/v1/suggestions',
      data: {
        'suggestedTitle': suggestedTitle,
        'suggestedAuthor': suggestedAuthor,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    if (res.statusCode == 401) {
      throw const SuggestionException('unauthorized', '로그인이 필요합니다.');
    }
    if (res.statusCode == 201 && res.data is Map) {
      final body = res.data as Map<String, dynamic>;
      return BookSuggestion.fromJson(body['data'] as Map<String, dynamic>);
    }
    if (res.data is Map) {
      final body = res.data as Map<String, dynamic>;
      throw SuggestionException(
        (body['error'] as String?) ?? 'unknown',
        (body['message'] as String?) ?? '제출에 실패했습니다.',
      );
    }
    throw SuggestionException(
      'unknown',
      '제출에 실패했습니다 (${res.statusCode}).',
    );
  }

  @override
  Future<List<BookSuggestion>> fetchMine() async {
    final res = await _dio.get<dynamic>('/v1/suggestions/my');
    if (res.statusCode == 401) {
      throw const SuggestionException('unauthorized', '로그인이 필요합니다.');
    }
    if (res.statusCode != 200 || res.data is! Map) {
      throw SuggestionException(
        'unknown',
        '제출 내역 조회 실패 (${res.statusCode}).',
      );
    }
    final body = res.data as Map<String, dynamic>;
    final list = body['data'] as List<dynamic>;
    return list
        .map((j) => BookSuggestion.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
