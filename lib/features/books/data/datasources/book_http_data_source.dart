import 'package:dio/dio.dart';

import '../models/book.dart';
import 'book_data_source.dart';

/// Reads books from the public `/api/v1/books` endpoints.
/// Authentication is not required (GET endpoints are public).
class BookHttpDataSource implements BookDataSource {
  BookHttpDataSource({required String baseUrl, Dio? httpClient})
      : _dio = httpClient ?? _build(baseUrl);

  static Dio _build(String baseUrl) => Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  final Dio _dio;

  @override
  Future<List<Book>> fetchBooks({int page = 1, int limit = 20}) async {
    final res = await _dio.get<dynamic>(
      '/v1/books',
      queryParameters: {'page': page, 'limit': limit},
    );
    return _readList(res);
  }

  @override
  Future<Book?> getBookById(String id) async {
    try {
      final res = await _dio.get<dynamic>('/v1/books/$id');
      if (res.statusCode == 200 && res.data is Map) {
        return Book.fromJson(res.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<Book>> searchBooks({String? query, String? category}) async {
    // Backend's `BookFilters` AND-combines title+author+category. We only map
    // the user-supplied query to `title` (the most common case). Author search
    // is a follow-up enhancement.
    final params = <String, dynamic>{'page': 1, 'limit': 50};
    if (query != null && query.isNotEmpty) params['title'] = query;
    if (category != null && category.isNotEmpty) params['category'] = category;

    final res = await _dio.get<dynamic>('/v1/books', queryParameters: params);
    return _readList(res);
  }

  List<Book> _readList(Response<dynamic> res) {
    final data = res.data;
    if (data is! Map || data['data'] is! List) {
      return const [];
    }
    final items = data['data'] as List<dynamic>;
    return items
        .map((json) => Book.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
