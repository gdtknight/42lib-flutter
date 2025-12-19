import 'package:equatable/equatable.dart';
import '../../models/student.dart';

/// Base class for authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - authentication status unknown
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State when checking authentication status
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State when user is authenticated
class Authenticated extends AuthState {
  final Student student;
  final String token;

  const Authenticated({
    required this.student,
    required this.token,
  });

  @override
  List<Object?> get props => [student, token];
}

/// State when user is not authenticated
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// State when OAuth login is in progress
class OAuthLoginInProgress extends AuthState {
  final String authUrl;

  const OAuthLoginInProgress({required this.authUrl});

  @override
  List<Object?> get props => [authUrl];
}

/// State when OAuth callback is being processed
class OAuthCallbackProcessing extends AuthState {
  const OAuthCallbackProcessing();
}

/// State when authentication fails
class AuthError extends AuthState {
  final String message;
  final String? code;
  final dynamic error;

  const AuthError({
    required this.message,
    this.code,
    this.error,
  });

  @override
  List<Object?> get props => [message, code, error];
}

/// State when token is being refreshed
class TokenRefreshing extends AuthState {
  const TokenRefreshing();
}

/// State when logout is in progress
class LogoutInProgress extends AuthState {
  const LogoutInProgress();
}
