abstract class AuthState {}

class AuthUninitialized extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String token;
  AuthAuthenticated({required this.token});
}

class AuthUnauthenticated extends AuthState {}

class AuthLoading extends AuthState {}