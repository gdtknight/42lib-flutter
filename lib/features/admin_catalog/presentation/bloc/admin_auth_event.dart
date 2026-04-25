import 'package:equatable/equatable.dart';

abstract class AdminAuthEvent extends Equatable {
  const AdminAuthEvent();

  @override
  List<Object?> get props => [];
}

class AdminAuthRequested extends AdminAuthEvent {
  final String username;
  final String password;

  const AdminAuthRequested({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

class AdminAuthSessionRestored extends AdminAuthEvent {
  const AdminAuthSessionRestored();
}

class AdminAuthLogoutRequested extends AdminAuthEvent {
  const AdminAuthLogoutRequested();
}
