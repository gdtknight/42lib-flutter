import 'package:equatable/equatable.dart';

/// Base class for authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check if user is authenticated
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

/// Event to start 42 OAuth login flow
class Login42OAuth extends AuthEvent {
  const Login42OAuth();
}

/// Event to handle OAuth callback
class HandleOAuthCallback extends AuthEvent {
  final String code;
  final String? state;

  const HandleOAuthCallback({
    required this.code,
    this.state,
  });

  @override
  List<Object?> get props => [code, state];
}

/// Event to logout user
class Logout extends AuthEvent {
  const Logout();
}

/// Event to refresh authentication token
class RefreshAuthToken extends AuthEvent {
  const RefreshAuthToken();
}

/// Event to clear authentication error
class ClearAuthError extends AuthEvent {
  const ClearAuthError();
}
