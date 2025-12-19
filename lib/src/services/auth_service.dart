// lib/src/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../helpers/login_auth_holder.dart';

class AuthService {
  static const _keyAuthHeader = 'Authorization'; // exact key used in SharedPreferences
  static const _keyExpiry = 'TokenExpiry';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_keyAuthHeader);
    return t;
  }

  Future<int?> getExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyExpiry);
  }

  /// Persist the full Authorization header and expiry millis.
  Future<void> persistToken(String authorizationHeader, int expiryMillis) async {
    final prefs = await SharedPreferences.getInstance();

    // Normalize expiry: if looks like seconds (<= 1e11), convert to ms
    int normalizedExpiry = expiryMillis;
    if (expiryMillis > 0 && expiryMillis < 100000000000) {
      normalizedExpiry = expiryMillis * 1000;
    }

    await prefs.setString(_keyAuthHeader, authorizationHeader);
    await prefs.setInt(_keyExpiry, normalizedExpiry);

    // Also update in-memory holder immediately
    AuthHolder.instance.setAuthorizationHeader(authorizationHeader);

    if (kDebugMode) debugPrint('[AuthService] Saved token and expiry: $normalizedExpiry');
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
    if (auth == null || auth.isEmpty) return false;
    if (expiry == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final valid = expiry > now;
    if (kDebugMode) debugPrint('[AuthService] isTokenValid: $valid (expiry: $expiry, now: $now)');
    return valid;
  }

  /// Restore token from prefs into AuthHolder on startup
  static Future<void> restoreToMemory() async {
    final prefs = await SharedPreferences.getInstance();
    final auth = prefs.getString(_keyAuthHeader);
    final expiry = prefs.getInt(_keyExpiry);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (auth != null && auth.isNotEmpty && expiry != null && expiry > now) {
      AuthHolder.instance.setAuthorizationHeader(auth);
      if (kDebugMode) debugPrint('[AuthService] Restored token to memory');
    } else {
      AuthHolder.instance.clear();
      if (kDebugMode) debugPrint('[AuthService] No valid token found to restore');
    }
  }
}
