import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/book_suggestions/data/models/book_suggestion.dart';
import 'package:lib_42_flutter/features/book_suggestions/data/models/collection_period.dart';
import 'package:lib_42_flutter/features/book_suggestions/data/repositories/admin_suggestion_repository_impl.dart';
import 'package:lib_42_flutter/features/book_suggestions/domain/repositories/admin_suggestion_repository.dart';

import '../../../../support/fake_dio_adapter.dart';
import '../../../../support/fake_secure_storage_service.dart';

AdminSuggestionRepositoryImpl _build(FakeDioAdapter adapter,
    {String? adminToken}) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.test',
    validateStatus: (s) => s != null && s < 500,
  ));
  dio.httpClientAdapter = adapter;
  return AdminSuggestionRepositoryImpl(
    baseUrl: 'https://api.test',
    httpClient: dio,
    storage: FakeSecureStorageService(adminToken: adminToken),
  );
}

const _suggestionJson = {
  'id': 's1',
  'studentId': 'stu-1',
  'suggestedTitle': '클린 아키텍처',
  'suggestedAuthor': 'R. Martin',
  'reason': '학습용',
  'collectionPeriodId': 'p1',
  'status': 'submitted',
  'submittedAt': '2024-02-01T00:00:00.000Z',
};

const _groupedJson = {
  'suggestedTitle': '클린 아키텍처',
  'suggestedAuthor': 'R. Martin',
  'collectionPeriodId': 'p1',
  'requesterCount': 2,
  'statuses': {'submitted': 1, 'approved': 1},
  'latestSubmittedAt': '2024-02-01T00:00:00.000Z',
  'items': [_suggestionJson],
};

const _periodJson = {
  'id': 'p1',
  'name': '2024 Q1',
  'startDate': '2024-01-01T00:00:00.000Z',
  'endDate': '2024-03-31T00:00:00.000Z',
  'status': 'active',
};

void main() {
  group('AdminSuggestionRepositoryImpl', () {
    test('fetchGrouped parses grouped payload', () async {
      final adapter = FakeDioAdapter()..enqueue(bodyList: [_groupedJson]);
      final repo = _build(adapter);

      final groups = await repo.fetchGrouped();

      expect(groups, hasLength(1));
      expect(groups.first.suggestedTitle, '클린 아키텍처');
      expect(groups.first.requesterCount, 2);
      expect(adapter.requests.single.path, '/v1/suggestions');
    });

    test('fetchGrouped passes periodId as query param', () async {
      final adapter = FakeDioAdapter()..enqueue(bodyList: const []);
      final repo = _build(adapter);

      await repo.fetchGrouped(periodId: 'p99');

      expect(adapter.requests.single.queryParameters['periodId'], 'p99');
    });

    test('fetchGrouped throws AdminSuggestionException on non-200', () async {
      // 4xx is below the 500 threshold so it returns to user code (does not
      // throw at Dio level), then the repository explicitly rejects non-200.
      final adapter = FakeDioAdapter()
        ..enqueue(statusCode: 401, body: {'error': 'unauthorized'});
      final repo = _build(adapter);

      await expectLater(
        repo.fetchGrouped(),
        throwsA(isA<AdminSuggestionException>()
            .having((e) => e.code, 'code', 'fetch_failed')),
      );
    });

    test('review returns updated suggestion with approved status', () async {
      final adapter = FakeDioAdapter()
        ..enqueue(statusCode: 200, body: {
          'data': {..._suggestionJson, 'status': 'approved'},
        });
      final repo = _build(adapter);

      final updated = await repo.review('s1',
          status: SuggestionStatus.approved, adminNotes: '구매 예정');

      expect(updated.id, 's1');
      expect(updated.status, SuggestionStatus.approved);
      expect(adapter.requests.single.method, 'PUT');
      expect(adapter.requests.single.path, '/v1/suggestions/s1/status');
      expect(adapter.lastRequestBody['status'], 'approved');
      expect(adapter.lastRequestBody['adminNotes'], '구매 예정');
    });

    test('review converts underReview to wire form `under_review`', () async {
      final adapter = FakeDioAdapter()
        ..enqueue(statusCode: 200, body: {
          'data': {..._suggestionJson, 'status': 'under_review'},
        });
      final repo = _build(adapter);

      await repo.review('s1', status: SuggestionStatus.underReview);

      expect(adapter.lastRequestBody['status'], 'under_review');
      // adminNotes omitted when null/empty.
      expect(adapter.lastRequestBody.containsKey('adminNotes'), isFalse);
    });

    test('review surfaces backend error message', () async {
      final adapter = FakeDioAdapter()
        ..enqueue(statusCode: 400, body: {
          'error': 'invalid_status',
          'message': '상태 전환이 허용되지 않습니다.',
        });
      final repo = _build(adapter);

      await expectLater(
        repo.review('s1', status: SuggestionStatus.approved),
        throwsA(isA<AdminSuggestionException>()
            .having((e) => e.code, 'code', 'invalid_status')
            .having((e) => e.message, 'message', '상태 전환이 허용되지 않습니다.')),
      );
    });

    test('createPeriod posts payload and returns CollectionPeriod', () async {
      final adapter = FakeDioAdapter()
        ..enqueue(statusCode: 201, body: {'data': _periodJson});
      final repo = _build(adapter);

      final period = await repo.createPeriod(
        name: '2024 Q1',
        startDate: DateTime.utc(2024, 1, 1),
        endDate: DateTime.utc(2024, 3, 31),
        status: PeriodStatus.active,
      );

      expect(period.id, 'p1');
      expect(period.status, PeriodStatus.active);
      expect(adapter.requests.single.path, '/v1/collection-periods');
      expect(adapter.lastRequestBody['name'], '2024 Q1');
      expect(adapter.lastRequestBody['status'], 'active');
    });

    test('createPeriod surfaces backend error message', () async {
      final adapter = FakeDioAdapter()
        ..enqueue(statusCode: 400, body: {
          'error': 'validation_error',
          'message': '시작일이 종료일보다 늦을 수 없습니다.',
        });
      final repo = _build(adapter);

      await expectLater(
        repo.createPeriod(
          name: 'X',
          startDate: DateTime.utc(2024, 4, 1),
          endDate: DateTime.utc(2024, 1, 1),
        ),
        throwsA(isA<AdminSuggestionException>()
            .having((e) => e.code, 'code', 'validation_error')),
      );
    });

    test('admin token is attached as Authorization header', () async {
      final adapter = FakeDioAdapter()..enqueue(bodyList: const []);
      final repo = _build(adapter, adminToken: 'admin-token');

      await repo.fetchGrouped();

      expect(adapter.requests.single.headers['Authorization'],
          'Bearer admin-token');
    });
  });
}
