import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/admin_catalog/data/models/administrator.dart';

void main() {
  group('Administrator model (T064)', () {
    test('parses admin role from JSON', () {
      final admin = Administrator.fromJson(const {
        'id': 'a1',
        'username': 'alice',
        'email': 'alice@42lib.kr',
        'fullName': 'Alice',
        'role': 'admin',
      });

      expect(admin.id, 'a1');
      expect(admin.username, 'alice');
      expect(admin.role, AdminRole.admin);
      expect(admin.isSuperAdmin, isFalse);
    });

    test('parses super_admin role from JSON', () {
      final admin = Administrator.fromJson(const {
        'id': 'a2',
        'username': 'root',
        'email': 'root@42lib.kr',
        'fullName': 'Root',
        'role': 'super_admin',
      });

      expect(admin.role, AdminRole.superAdmin);
      expect(admin.isSuperAdmin, isTrue);
    });

    test('throws on unknown role', () {
      expect(
        () => Administrator.fromJson(const {
          'id': 'a3',
          'username': 'x',
          'email': 'x@42lib.kr',
          'fullName': 'X',
          'role': 'pirate',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('serializes roundtrip', () {
      const original = Administrator(
        id: 'a4',
        username: 'bob',
        email: 'bob@42lib.kr',
        fullName: 'Bob',
        role: AdminRole.superAdmin,
      );

      final parsed = Administrator.fromJson(original.toJson());

      expect(parsed, equals(original));
      expect(original.toJson()['role'], 'super_admin');
    });

    test('Equatable compares by value', () {
      const a = Administrator(
        id: 'a5',
        username: 'carol',
        email: 'carol@42lib.kr',
        fullName: 'Carol',
        role: AdminRole.admin,
      );
      const b = Administrator(
        id: 'a5',
        username: 'carol',
        email: 'carol@42lib.kr',
        fullName: 'Carol',
        role: AdminRole.admin,
      );

      expect(a, equals(b));
    });
  });
}
