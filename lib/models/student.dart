import 'package:json_annotation/json_annotation.dart';

part 'student.g.dart';

@JsonSerializable()
class Student {
  final String id;
  final int fortytwoUserId;
  final String username;
  final String email;
  final String fullName;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  Student({
    required this.id,
    required this.fortytwoUserId,
    required this.username,
    required this.email,
    required this.fullName,
    required this.createdAt,
    required this.lastLoginAt,
  }) {
    _validate();
  }

  void _validate() {
    // VR-102: email must be valid email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      throw ArgumentError('Invalid email format');
    }

    // VR-101: fortytwoUserId must be unique (enforced at DB level)
    if (fortytwoUserId <= 0) {
      throw ArgumentError('42 User ID must be positive');
    }

    // Username constraints
    if (username.trim().isEmpty || username.length > 50) {
      throw ArgumentError('Username must be 1-50 characters');
    }

    // Full name constraints
    if (fullName.trim().isEmpty || fullName.length > 200) {
      throw ArgumentError('Full name must be 1-200 characters');
    }
  }

  /// Create Student from JSON
  factory Student.fromJson(Map<String, dynamic> json) =>
      _$StudentFromJson(json);

  /// Convert Student to JSON
  Map<String, dynamic> toJson() => _$StudentToJson(this);

  /// Create a copy of Student with updated fields
  Student copyWith({
    String? id,
    int? fortytwoUserId,
    String? username,
    String? email,
    String? fullName,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return Student(
      id: id ?? this.id,
      fortytwoUserId: fortytwoUserId ?? this.fortytwoUserId,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Student && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Student(id: $id, username: $username, fortytwoUserId: $fortytwoUserId)';
  }
}
