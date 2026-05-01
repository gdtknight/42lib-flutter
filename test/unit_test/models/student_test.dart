import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/models/student.dart';

Student _build({
  String id = 's1',
  int fortytwoUserId = 12345,
  String username = 'alice',
  String email = 'alice@42.fr',
  String fullName = '앨리스',
}) {
  return Student(
    id: id,
    fortytwoUserId: fortytwoUserId,
    username: username,
    email: email,
    fullName: fullName,
    createdAt: DateTime(2024, 1, 1),
    lastLoginAt: DateTime(2024, 1, 2),
  );
}

void main() {
  group('Student model (T095)', () {
    test('creates valid student', () {
      final s = _build();
      expect(s.id, 's1');
      expect(s.fortytwoUserId, 12345);
    });

    test('rejects invalid email format', () {
      expect(
        () => _build(email: 'not-an-email'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects non-positive fortytwoUserId', () {
      expect(() => _build(fortytwoUserId: 0), throwsA(isA<ArgumentError>()));
      expect(() => _build(fortytwoUserId: -5), throwsA(isA<ArgumentError>()));
    });

    test('rejects empty or too-long username', () {
      expect(() => _build(username: ''), throwsA(isA<ArgumentError>()));
      expect(() => _build(username: '   '), throwsA(isA<ArgumentError>()));
      expect(() => _build(username: 'x' * 51), throwsA(isA<ArgumentError>()));
    });

    test('rejects empty or too-long fullName', () {
      expect(() => _build(fullName: ''), throwsA(isA<ArgumentError>()));
      expect(() => _build(fullName: 'x' * 201), throwsA(isA<ArgumentError>()));
    });

    test('JSON roundtrip preserves fields', () {
      final original = _build();
      final parsed = Student.fromJson(original.toJson());
      expect(parsed, equals(original));
      expect(parsed.username, 'alice');
      expect(parsed.fullName, '앨리스');
    });

    test('equality compared by id', () {
      final a = _build(id: 's1', username: 'a');
      final b = _build(id: 's1', username: 'b');
      expect(a, equals(b));
    });
  });
}
