// lib/src/helpers/auth_holder.dart
/// In-memory holder for authorization header (e.g. "Bearer abc...").
/// Use AuthHolder.instance.authorizationHeader when making requests.
/// This avoids reading SharedPreferences on every request.
class AuthHolder {
  AuthHolder._();

  static final AuthHolder instance = AuthHolder._();

  String? _authorizationHeader; // full "Bearer ..." string

  bool get hasToken => _authorizationHeader != null && _authorizationHeader!.isNotEmpty;

  /// Example: "Bearer eyJ..."
  String get authorizationHeader => _authorizationHeader ?? '';

  /// Set the full Authorization header in memory (e.g. "Bearer <token>")
  void setAuthorizationHeader(String header) {
    _authorizationHeader = header;
  }

  /// Clear in-memory token
  void clear() {
    _authorizationHeader = null;
  }
}