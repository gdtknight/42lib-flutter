import 'package:equatable/equatable.dart';

enum AdminRole { admin, superAdmin }

AdminRole _parseRole(String raw) {
  switch (raw) {
    case 'super_admin':
      return AdminRole.superAdmin;
    case 'admin':
      return AdminRole.admin;
    default:
      throw ArgumentError('Unknown admin role: $raw');
  }
}

String _roleToJson(AdminRole role) =>
    role == AdminRole.superAdmin ? 'super_admin' : 'admin';

class Administrator extends Equatable {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final AdminRole role;

  const Administrator({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory Administrator.fromJson(Map<String, dynamic> json) {
    return Administrator(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: _parseRole(json['role'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'username': username,
        'email': email,
        'fullName': fullName,
        'role': _roleToJson(role),
      };

  bool get isSuperAdmin => role == AdminRole.superAdmin;

  @override
  List<Object?> get props => [id, username, email, fullName, role];
}
