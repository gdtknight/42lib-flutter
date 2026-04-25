import 'package:equatable/equatable.dart';

import '../../data/models/administrator.dart';
import '../../domain/repositories/admin_auth_repository.dart';

abstract class AdminAuthState extends Equatable {
  const AdminAuthState();

  @override
  List<Object?> get props => [];
}

class AdminAuthInitial extends AdminAuthState {
  const AdminAuthInitial();
}

class AdminAuthLoading extends AdminAuthState {
  const AdminAuthLoading();
}

class AdminAuthenticated extends AdminAuthState {
  final Administrator admin;
  final String token;

  const AdminAuthenticated({required this.admin, required this.token});

  @override
  List<Object?> get props => [admin, token];
}

class AdminUnauthenticated extends AdminAuthState {
  const AdminUnauthenticated();
}

class AdminAuthFailed extends AdminAuthState {
  final AdminAuthFailure failure;
  final String message;

  const AdminAuthFailed({required this.failure, required this.message});

  @override
  List<Object?> get props => [failure, message];
}
