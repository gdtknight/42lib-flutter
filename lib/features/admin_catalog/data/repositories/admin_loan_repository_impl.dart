import 'package:dio/dio.dart';

import '../../../../services/storage/secure_storage_service.dart';
import '../../domain/repositories/admin_loan_repository.dart';
import '../models/loan.dart';

class AdminLoanRepositoryImpl implements AdminLoanRepository {
  AdminLoanRepositoryImpl({
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
  Future<List<AdminLoanRequest>> fetchPendingRequests() async {
    final res = await _dio.get<dynamic>('/v1/loan-requests');
    if (res.statusCode != 200 || res.data is! Map) {
      throw LoanOperationException(
        'fetch_failed',
        '대출 요청 목록을 불러오지 못했습니다 (${res.statusCode}).',
      );
    }
    final list = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return list
        .map((j) => AdminLoanRequest.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Loan>> fetchLoans({String? status}) async {
    final res = await _dio.get<dynamic>(
      '/v1/loans',
      queryParameters: {
        if (status != null) 'status': status,
        'limit': 100,
      },
    );
    if (res.statusCode != 200 || res.data is! Map) {
      throw LoanOperationException(
        'fetch_failed',
        '대출 목록을 불러오지 못했습니다 (${res.statusCode}).',
      );
    }
    final list = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return list.map((j) => Loan.fromJson(j as Map<String, dynamic>)).toList();
  }

  @override
  Future<Loan> approveRequest(
    String requestId, {
    int? dueInDays,
    String? notes,
  }) async {
    final res = await _dio.put<dynamic>(
      '/v1/loan-requests/$requestId/approve',
      data: {
        if (dueInDays != null) 'dueInDays': dueInDays,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return _expectLoan(res, 'approve_failed');
  }

  @override
  Future<AdminLoanRequest> rejectRequest(String requestId, String reason) async {
    final res = await _dio.put<dynamic>(
      '/v1/loan-requests/$requestId/reject',
      data: {'rejectionReason': reason},
    );
    if (res.statusCode == 200 && res.data is Map) {
      final body = res.data as Map<String, dynamic>;
      return AdminLoanRequest.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw LoanOperationException(
      'reject_failed',
      _readMessage(res, '반려 처리에 실패했습니다.'),
    );
  }

  @override
  Future<Loan> returnLoan(String loanId) async {
    final res = await _dio.put<dynamic>('/v1/loans/$loanId/return');
    return _expectLoan(res, 'return_failed');
  }

  Loan _expectLoan(Response<dynamic> res, String fallbackCode) {
    if (res.statusCode == 200 && res.data is Map) {
      final body = res.data as Map<String, dynamic>;
      return Loan.fromJson(body['data'] as Map<String, dynamic>);
    }
    if (res.data is Map) {
      final body = res.data as Map<String, dynamic>;
      throw LoanOperationException(
        (body['error'] as String?) ?? fallbackCode,
        (body['message'] as String?) ?? '처리에 실패했습니다.',
      );
    }
    throw LoanOperationException(fallbackCode, '처리에 실패했습니다 (${res.statusCode}).');
  }

  String _readMessage(Response<dynamic> res, String fallback) {
    if (res.data is Map) {
      final body = res.data as Map<String, dynamic>;
      return (body['message'] as String?) ?? fallback;
    }
    return fallback;
  }
}
