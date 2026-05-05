import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/services/storage/secure_storage_service.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Stand-in for [SecureStorageService] that doesn't touch the platform
/// channel. Only [readAdminToken] is exposed — extend as needed.
class FakeSecureStorageService extends SecureStorageService {
  FakeSecureStorageService({this.adminToken = 'test-admin-token'})
      : super(storage: const _NoopFlutterSecureStorage());

  String? adminToken;

  @override
  Future<String?> readAdminToken() async => adminToken;
}

/// FlutterSecureStorage that throws if any platform call slips through.
/// Construction requires no platform channel because we never call into it.
class _NoopFlutterSecureStorage implements FlutterSecureStorage {
  const _NoopFlutterSecureStorage();

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Real storage call leaked into test');
}

/// Optional helper: install a no-op platform handler so any code path that
/// instantiates a real SecureStorageService doesn't crash. Call from
/// `setUpAll` if needed.
void installNoopSecureStoragePlatform() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStoragePlatform.instance = _NoopPlatform();
}

/// Install an in-memory platform handler that actually round-trips values
/// through a backing Map. Returns the live store so tests can assert state.
/// Call from `setUp` and reset between tests.
Map<String, String> installInMemorySecureStoragePlatform() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = <String, String>{};
  FlutterSecureStoragePlatform.instance = _InMemoryPlatform(store);
  return store;
}

class _NoopPlatform extends FlutterSecureStoragePlatform with MockPlatformInterfaceMixin {
  @override
  Future<bool> containsKey(
          {required String key, required Map<String, String> options}) async =>
      false;

  @override
  Future<void> delete(
      {required String key, required Map<String, String> options}) async {}

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {}

  @override
  Future<String?> read(
          {required String key, required Map<String, String> options}) async =>
      null;

  @override
  Future<Map<String, String>> readAll(
          {required Map<String, String> options}) async =>
      {};

  @override
  Future<void> write(
      {required String key,
      required String value,
      required Map<String, String> options}) async {}
}

class _InMemoryPlatform extends FlutterSecureStoragePlatform with MockPlatformInterfaceMixin {
  _InMemoryPlatform(this._store);
  final Map<String, String> _store;

  @override
  Future<bool> containsKey(
          {required String key, required Map<String, String> options}) async =>
      _store.containsKey(key);

  @override
  Future<void> delete(
      {required String key, required Map<String, String> options}) async {
    _store.remove(key);
  }

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    _store.clear();
  }

  @override
  Future<String?> read(
          {required String key, required Map<String, String> options}) async =>
      _store[key];

  @override
  Future<Map<String, String>> readAll(
          {required Map<String, String> options}) async =>
      Map.of(_store);

  @override
  Future<void> write(
      {required String key,
      required String value,
      required Map<String, String> options}) async {
    _store[key] = value;
  }
}
