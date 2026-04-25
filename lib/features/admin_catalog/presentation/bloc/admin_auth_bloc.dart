import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/admin_auth_repository.dart';
import 'admin_auth_event.dart';
import 'admin_auth_state.dart';

class AdminAuthBloc extends Bloc<AdminAuthEvent, AdminAuthState> {
  final AdminAuthRepository repository;

  AdminAuthBloc({required this.repository}) : super(const AdminAuthInitial()) {
    on<AdminAuthRequested>(_onLoginRequested);
    on<AdminAuthSessionRestored>(_onSessionRestored);
    on<AdminAuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(
    AdminAuthRequested event,
    Emitter<AdminAuthState> emit,
  ) async {
    emit(const AdminAuthLoading());
    try {
      final result = await repository.login(
        username: event.username,
        password: event.password,
      );
      emit(AdminAuthenticated(admin: result.admin, token: result.token));
    } on AdminAuthException catch (e) {
      emit(AdminAuthFailed(failure: e.failure, message: e.message));
    }
  }

  Future<void> _onSessionRestored(
    AdminAuthSessionRestored event,
    Emitter<AdminAuthState> emit,
  ) async {
    final result = await repository.restoreSession();
    if (result == null) {
      emit(const AdminUnauthenticated());
    } else {
      emit(AdminAuthenticated(admin: result.admin, token: result.token));
    }
  }

  Future<void> _onLogoutRequested(
    AdminAuthLogoutRequested event,
    Emitter<AdminAuthState> emit,
  ) async {
    await repository.logout();
    emit(const AdminUnauthenticated());
  }
}
