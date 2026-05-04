import 'package:dio/dio.dart';

import '../../../../services/storage/secure_storage_service.dart';
import '../../domain/repositories/admin_suggestion_repository.dart';
import '../models/book_suggestion.dart';
import '../models/collection_period.dart';
import '../models/grouped_suggestion.dart';

class AdminSuggestionRepositoryImpl implements AdminSuggestionRepository {
  AdminSuggestionRepositoryImpl({
    required String baseUrl,
    SecureStorageService? storage,
    Dio? httpClient,
  })  : _storage = storage ?? SecureStorageService(),
        _dio = httpClient ?? _build(baseUrl) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.readAdminToken();
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
  Future<List<GroupedSuggestion>> fetchGrouped({String? periodId}) async {
    final res = await _dio.get<dynamic>(
      '/v1/suggestions',
      queryParameters: {if (periodId != null) 'periodId': periodId},
    );
    if (res.statusCode != 200 || res.data is! Map) {
      throw AdminSuggestionException(
        'fetch_failed',
        '추천 목록을 불러오지 못했습니다 (${res.statusCode}).',
      );
    }
    final list = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return list
        .map((j) => GroupedSuggestion.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BookSuggestion> review(
    String suggestionId, {
    required SuggestionStatus status,
    String? adminNotes,
  }) async {
    final res = await _dio.put<dynamic>(
      '/v1/suggestions/$suggestionId/status',
      data: {
        'status': _statusToWire(status),
        if (adminNotes != null && adminNotes.isNotEmpty)
          'adminNotes': adminNotes,
      },
    );
    if (res.statusCode == 200 && res.data is Map) {
      final body = res.data as Map<String, dynamic>;
      return BookSuggestion.fromJson(body['data'] as Map<String, dynamic>);
    }
    if (res.data is Map) {
      final body = res.data as Map<String, dynamic>;
      throw AdminSuggestionException(
        (body['error'] as String?) ?? 'review_failed',
        (body['message'] as String?) ?? '검토 처리에 실패했습니다.',
      );
    }
    throw AdminSuggestionException(
      'review_failed',
      '검토 처리에 실패했습니다 (${res.statusCode}).',
    );
  }

  @override
  Future<CollectionPeriod> createPeriod({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    PeriodStatus status = PeriodStatus.upcoming,
  }) async {
    final res = await _dio.post<dynamic>(
      '/v1/collection-periods',
      data: {
        'name': name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'status': _periodStatusToWire(status),
      },
    );
    if (res.statusCode == 201 && res.data is Map) {
      final body = res.data as Map<String, dynamic>;
      return CollectionPeriod.fromJson(body['data'] as Map<String, dynamic>);
    }
    if (res.data is Map) {
      final body = res.data as Map<String, dynamic>;
      throw AdminSuggestionException(
        (body['error'] as String?) ?? 'create_period_failed',
        (body['message'] as String?) ?? '기간 생성에 실패했습니다.',
      );
    }
    throw AdminSuggestionException(
      'create_period_failed',
      '기간 생성에 실패했습니다 (${res.statusCode}).',
    );
  }

  static String _statusToWire(SuggestionStatus s) {
    switch (s) {
      case SuggestionStatus.submitted:
        return 'submitted';
      case SuggestionStatus.approved:
        return 'approved';
      case SuggestionStatus.rejected:
        return 'rejected';
      case SuggestionStatus.underReview:
        return 'under_review';
    }
  }

  static String _periodStatusToWire(PeriodStatus s) {
    switch (s) {
      case PeriodStatus.upcoming:
        return 'upcoming';
      case PeriodStatus.active:
        return 'active';
      case PeriodStatus.closed:
        return 'closed';
    }
  }
}
