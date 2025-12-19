// lib/src/helpers/login_auth_holder.dart
import 'package:flutter/foundation.dart';

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
    if (kDebugMode) {
      // Log the full header so you can see nothing is trimmed in memory
      debugPrint('[AuthHolder] Updating active token: $header');
    }
    _authorizationHeader = header;
  }

  /// Clear in-memory token
  void clear() {
    if (kDebugMode) debugPrint('[AuthHolder] Clearing active token');
    _authorizationHeader = null;
  }
}
