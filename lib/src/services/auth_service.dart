// lib/src/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/login_auth_holder.dart';

class AuthService {
  static const _keyAuthHeader = 'Authorization'; // existing key in your app
  static const _keyExpiry = 'TokenExpiry';

  /// Returns stored Authorization header (e.g. "Bearer ...") or null
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthHeader);
  }

  Future<int?> getExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyExpiry);
  }

  /// Persist the full Authorization header and expiry millis
  Future<void> persistToken(String authorizationHeader, int expiryMillis) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthHeader, authorizationHeader);
    await prefs.setInt(_keyExpiry, expiryMillis);
    // also set in-memory holder for fast access
    AuthHolder.instance.setAuthorizationHeader(authorizationHeader);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAuthHeader);
    await prefs.remove(_keyExpiry);
    AuthHolder.instance.clear();
  }

  Future<bool> isTokenValid() async {
    final auth = await getToken();
    final expiry = await getExpiry();
    if (auth == null || auth.isEmpty || expiry == null) return false;
    return expiry > DateTime.now().millisecondsSinceEpoch;
  }

  /// Convenience: restore token from SharedPreferences into AuthHolder (call on app start)
  static Future<void> restoreToMemory() async {
    final prefs = await SharedPreferences.getInstance();
    final auth = prefs.getString(_keyAuthHeader);
    final expiry = prefs.getInt(_keyExpiry);
    if (auth != null && auth.isNotEmpty && expiry != null && expiry > DateTime.now().millisecondsSinceEpoch) {
      AuthHolder.instance.setAuthorizationHeader(auth);
    } else {
      AuthHolder.instance.clear();
    }
  }
}