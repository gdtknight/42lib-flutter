import 'package:dio/dio.dart';

import '../../../books/data/models/book.dart';
import '../../../../services/storage/secure_storage_service.dart';
import '../../domain/repositories/admin_book_repository.dart';

/// HTTP-backed admin book repository. Uses a dedicated Dio instance with an
/// interceptor that injects the admin JWT from secure storage on every call.
class AdminBookRepositoryImpl implements AdminBookRepository {
  AdminBookRepositoryImpl({
    required String baseUrl,
    SecureStorageService? storage,
    Dio? httpClient,
  })  : _storage = storage ?? SecureStorageService(),
        _dio = httpClient ?? _buildDio(baseUrl) {
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

  static Dio _buildDio(String baseUrl) => Dio(
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
  Future<List<Book>> fetchBooks() async {
    final response = await _dio.get<dynamic>(
      '/v1/books',
      queryParameters: {'page': 1, 'limit': 200},
    );
    if (response.statusCode != 200 || response.data is! Map) {
      throw BookConflictException('Failed to load books (${response.statusCode})');
    }
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data
        .map((json) => Book.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Book> createBook(AdminBookPayload payload) async {
    final response = await _dio.post<dynamic>(
      '/v1/books',
      data: payload.toJson(),
    );
    return _expectBook(response, expected: 201);
  }

  @override
  Future<Book> updateBook(String id, AdminBookPayload payload) async {
    final response = await _dio.put<dynamic>(
      '/v1/books/$id',
      data: payload.toJson(),
    );
    return _expectBook(response, expected: 200);
  }

  @override
  Future<void> deleteBook(String id) async {
    final response = await _dio.delete<dynamic>('/v1/books/$id');
    if (response.statusCode == 204) return;

    if (response.statusCode == 409 && response.data is Map) {
      final body = response.data as Map<String, dynamic>;
      throw BookInUseException(
        activeLoans: (body['activeLoans'] as int?) ?? 0,
        pendingRequests: (body['pendingRequests'] as int?) ?? 0,
      );
    }
    throw BookConflictException('Failed to delete book (${response.statusCode})');
  }

  Book _expectBook(Response<dynamic> response, {required int expected}) {
    if (response.statusCode == expected && response.data is Map) {
      return Book.fromJson(response.data as Map<String, dynamic>);
    }
    if (response.statusCode == 400 && response.data is Map) {
      final body = response.data as Map<String, dynamic>;
      throw BookConflictException(
        (body['error'] as String?) ?? 'Validation error',
      );
    }
    throw BookConflictException('Unexpected response (${response.statusCode})');
  }
}
