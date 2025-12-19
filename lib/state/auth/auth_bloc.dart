import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth/auth_42_client.dart';
import '../../services/storage/secure_storage_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC for managing authentication with 42 OAuth
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Auth42Client auth42Client;
  final SecureStorageService secureStorage;

  AuthBloc({
    required this.auth42Client,
    required this.secureStorage,
  }) : super(const AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<Login42OAuth>(_onLogin42OAuth);
    on<HandleOAuthCallback>(_onHandleOAuthCallback);
    on<Logout>(_onLogout);
    on<RefreshAuthToken>(_onRefreshAuthToken);
    on<ClearAuthError>(_onClearAuthError);
  }

  /// Check if user is already authenticated
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      final isAuth = await auth42Client.isAuthenticated();

      if (isAuth) {
        // Get current user profile
        final student = await auth42Client.getCurrentStudent();
        final token = await auth42Client.getToken();

        emit(Authenticated(
          student: student,
          token: token ?? '',
        ));
      } else {
        emit(const Unauthenticated());
      }
    } catch (error) {
      emit(const Unauthenticated());
    }
  }

  /// Start 42 OAuth login flow
  Future<void> _onLogin42OAuth(
    Login42OAuth event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final authUrl = auth42Client.getAuthorizationUrl(
        state: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      emit(OAuthLoginInProgress(authUrl: authUrl));
    } catch (error) {
      emit(AuthError(
        message: 'OAuth 로그인 URL 생성 중 오류가 발생했습니다',
        error: error,
      ));
    }
  }

  /// Handle OAuth callback with authorization code
  Future<void> _onHandleOAuthCallback(
    HandleOAuthCallback event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const OAuthCallbackProcessing());

      // Exchange code for token
      final tokenData = await auth42Client.exchangeCodeForToken(event.code);

      // Get user profile
      final student = await auth42Client.getCurrentStudent();
      final token = tokenData['token'] as String;

      emit(Authenticated(
        student: student,
        token: token,
      ));
    } catch (error) {
      emit(AuthError(
        message: 'OAuth 인증 중 오류가 발생했습니다',
        error: error,
      ));
    }
  }

  /// Logout user
  Future<void> _onLogout(
    Logout event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const LogoutInProgress());

      await auth42Client.logout();

      emit(const Unauthenticated());
    } catch (error) {
      emit(AuthError(
        message: '로그아웃 중 오류가 발생했습니다',
        error: error,
      ));
    }
  }

  /// Refresh authentication token
  Future<void> _onRefreshAuthToken(
    RefreshAuthToken event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const TokenRefreshing());

      final newToken = await auth42Client.refreshToken();
      final student = await auth42Client.getCurrentStudent();

      emit(Authenticated(
        student: student,
        token: newToken,
      ));
    } catch (error) {
      emit(AuthError(
        message: '토큰 갱신 중 오류가 발생했습니다. 다시 로그인해주세요.',
        error: error,
      ));
      // Token refresh failed, user needs to login again
      add(const Logout());
    }
  }

  /// Clear authentication error
  Future<void> _onClearAuthError(
    ClearAuthError event,
    Emitter<AuthState> emit,
  ) async {
    emit(const Unauthenticated());
  }
}
