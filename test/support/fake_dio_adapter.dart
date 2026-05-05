import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Minimal Dio adapter for tests. Records every request and serves canned
/// responses queued via [enqueue]. The default response when the queue is
/// empty is 200 OK with the body `{ "data": [] }`, which keeps tests forgiving
/// about unrelated bookkeeping calls.
class FakeDioAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<_FakeResponse> _queue = [];
  bool throwTimeout = false;

  void enqueue({
    int statusCode = 200,
    Map<String, dynamic>? body,
    List<dynamic>? bodyList,
    String? rawBody,
  }) {
    final encoded = rawBody ??
        jsonEncode(bodyList != null ? {'data': bodyList} : (body ?? {}));
    _queue.add(_FakeResponse(statusCode: statusCode, body: encoded));
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
        : _FakeResponse(statusCode: 200, body: jsonEncode({'data': []}));
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

class _FakeResponse {
  _FakeResponse({required this.statusCode, required this.body});
  final int statusCode;
  final String body;
}
