import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/services/auth/auth_42_client.dart';
import 'package:lib_42_flutter/services/storage/secure_storage_service.dart';

import '../../support/fake_dio_adapter.dart';
import '../../support/fake_secure_storage_service.dart';

Auth42Client _build(FakeDioAdapter adapter, SecureStorageService storage) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.test',
    validateStatus: (_) => true,
  ));
  dio.httpClientAdapter = adapter;
  return Auth42Client(
    dio: dio,
    secureStorage: storage,
    baseUrl: 'https://api.intra.42.fr',
    clientId: 'client-123',
    redirectUri: 'http://localhost:3000/api/v1/auth/42/callback',
  );
}

const _studentJson = {
  'id': 'stu-1',
  'fortytwoUserId': 12345,
  'username': 'yoshin',
  'email': 'yoshin@42.fr',
  'fullName': '신용기',
  'createdAt': '2024-01-01T00:00:00.000Z',
  'lastLoginAt': '2024-02-01T00:00:00.000Z',
};

void main() {
  late Map<String, String> store;
  late SecureStorageService storage;

  setUp(() {
    store = installInMemorySecureStoragePlatform();
    storage = SecureStorageService(storage: const FlutterSecureStorage());
  });

  group('Auth42Client.getAuthorizationUrl', () {
    test('builds the 42 OAuth URL with required params', () {
      final client = _build(FakeDioAdapter(), storage);
      final url = client.getAuthorizationUrl();

      expect(url, startsWith('https://api.intra.42.fr/oauth/authorize?'));
      expect(url, contains('client_id=client-123'));
      expect(url, contains('response_type=code'));
      expect(url, contains('scope=public'));
      // redirect_uri should be percent-encoded.
      expect(
        url,
        contains(
          'redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fapi%2Fv1%2Fauth%2F42%2Fcallback',
        ),
      );
    });

    test('includes state when provided', () {
      final client = _build(FakeDioAdapter(), storage);
      final url = client.getAuthorizationUrl(state: 'abc-xyz');
      expect(url, contains('state=abc-xyz'));
    });
  });

  group('Auth42Client.exchangeCodeForToken', () {
    test('stores JWT + refresh tokens on 200', () async {
      final adapter = FakeDioAdapter()
        ..enqueue(body: {'token': 'jwt-1', 'refreshToken': 'rt-1'});
      final client = _build(adapter, storage);

      final data = await client.exchangeCodeForToken('the-code');

      expect(data['token'], 'jwt-1');
      expect(store['jwt_token'], 'jwt-1');
      expect(store['refresh_token'], 'rt-1');
      expect(adapter.requests.single.path, '/auth/42/callback');
      expect(adapter.requests.single.queryParameters['code'], 'the-code');
    });

    test('throws Korean message on 401 (DioException path)', () async {
      final adapter = FakeDioAdapter()..enqueueDioError(statusCode: 401);
      final client = _build(adapter, storage);

      await expectLater(
        client.exchangeCodeForToken('bad-code'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('42 OAuth 인증에 실패'),
        )),
      );
    });

    test('throws Korean message on 400 (DioException path)', () async {
      final adapter = FakeDioAdapter()..enqueueDioError(statusCode: 400);
      final client = _build(adapter, storage);

      await expectLater(
        client.exchangeCodeForToken('malformed'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('잘못된 인증 코드'),
        )),
      );
    });
  });

  group('Auth42Client.getCurrentStudent', () {
    test('returns Student on 200 with bearer token', () async {
      await storage.writeToken('jwt-1');
      final adapter = FakeDioAdapter()..enqueue(body: _studentJson);
      final client = _build(adapter, storage);

      final s = await client.getCurrentStudent();

      expect(s.username, 'yoshin');
      expect(adapter.requests.single.path, '/auth/me');
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer jwt-1',
      );
    });

    test('throws when no token stored', () async {
      final adapter = FakeDioAdapter();
      final client = _build(adapter, storage);

      await expectLater(
        client.getCurrentStudent(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('인증 토큰'),
        )),
      );
    });
  });

  group('Auth42Client.refreshToken', () {
    test('rotates JWT (and refresh) on 200', () async {
      await storage.writeRefreshToken('rt-old');
      final adapter = FakeDioAdapter()
        ..enqueue(body: {'token': 'jwt-2', 'refreshToken': 'rt-new'});
      final client = _build(adapter, storage);

      final newToken = await client.refreshToken();

      expect(newToken, 'jwt-2');
      expect(store['jwt_token'], 'jwt-2');
      expect(store['refresh_token'], 'rt-new');
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/auth/refresh');
    });

    test('throws when no refresh token stored', () async {
      final adapter = FakeDioAdapter();
      final client = _build(adapter, storage);

      await expectLater(
        client.refreshToken(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('리프레시 토큰'),
        )),
      );
    });
  });

  group('Auth42Client — auth state helpers', () {
    test('logout clears jwt + refresh tokens', () async {
      await storage.writeToken('jwt');
      await storage.writeRefreshToken('rt');
      final client = _build(FakeDioAdapter(), storage);

      await client.logout();

      expect(store.containsKey('jwt_token'), isFalse);
      expect(store.containsKey('refresh_token'), isFalse);
    });

    test('isAuthenticated reflects token presence', () async {
      final client = _build(FakeDioAdapter(), storage);
      expect(await client.isAuthenticated(), isFalse);
      await storage.writeToken('jwt');
      expect(await client.isAuthenticated(), isTrue);
    });

    test('getToken returns the stored JWT', () async {
      await storage.writeToken('jwt-xyz');
      final client = _build(FakeDioAdapter(), storage);
      expect(await client.getToken(), 'jwt-xyz');
    });
  });
}
