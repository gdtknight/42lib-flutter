import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Minimal Dio adapter for tests. Records every request and serves canned
/// responses queued via [enqueue]. The default response when the queue is
/// empty is 200 OK with the body `{ "data": [] }`, which keeps tests forgiving
/// about unrelated bookkeeping calls.
class FakeDioAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<_FakeEntry> _queue = [];
  bool throwTimeout = false;

  void enqueue({
    int statusCode = 200,
    Map<String, dynamic>? body,
    List<dynamic>? bodyList,
    String? rawBody,
  }) {
    final encoded = rawBody ??
        jsonEncode(bodyList != null ? {'data': bodyList} : (body ?? {}));
    _queue.add(_FakeEntry.response(statusCode: statusCode, body: encoded));
  }

  /// Queue a DioException with a Response payload so the production code's
  /// `on DioException` branches (e.g. 401 handling) can be exercised even
  /// when the test's outer Dio is configured permissively.
  void enqueueDioError({
    int statusCode = 401,
    Map<String, dynamic>? body,
    DioExceptionType type = DioExceptionType.badResponse,
  }) {
    _queue.add(_FakeEntry.error(
      statusCode: statusCode,
      body: jsonEncode(body ?? {}),
      type: type,
    ));
  }

  /// Most recent request's body decoded as JSON. Throws if no requests.
  Map<String, dynamic> get lastRequestBody {
    final r = requests.last;
    final raw = r.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
    throw StateError('Unsupported request body type: ${raw.runtimeType}');
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    requests.add(options);
    if (throwTimeout) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
        message: 'fake timeout',
      );
    }
    final canned = _queue.isNotEmpty
        ? _queue.removeAt(0)
        : _FakeEntry.response(statusCode: 200, body: jsonEncode({'data': []}));

    if (canned.error != null) {
      throw DioException(
        requestOptions: options,
        type: canned.error!,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: canned.statusCode,
          data: canned.body.isEmpty ? null : jsonDecode(canned.body),
        ),
      );
    }

    return ResponseBody.fromString(
      canned.body,
      canned.statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeEntry {
  _FakeEntry.response({required this.statusCode, required this.body})
      : error = null;
  _FakeEntry.error({
    required this.statusCode,
    required this.body,
    required DioExceptionType type,
  }) : error = type;

  final int statusCode;
  final String body;
  final DioExceptionType? error;
}
