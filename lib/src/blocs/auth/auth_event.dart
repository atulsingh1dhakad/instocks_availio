abstract class AuthEvent {}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  final String token;
  final int expiryMillis;

  LoggedIn({required this.token, required this.expiryMillis});
}

class LoggedOut extends AuthEvent {}