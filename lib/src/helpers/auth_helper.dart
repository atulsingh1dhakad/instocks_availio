// lib/src/helpers/auth_helper.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_auth_holder.dart';

class AuthHelper {
  /// Returns headers including x-api-token and Authorization.
  /// Standardized to use the full Authorization header from memory or cache.
  static Future<Map<String, String>> getAuthHeaders({String? apiToken, bool multipart = false}) async {
    // 1. Try memory holder first (populated on app start)
    String auth = AuthHolder.instance.authorizationHeader;

    // 2. Fallback to SharedPreferences if memory is empty
    if (auth.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      auth = prefs.getString('Authorization') ?? '';
      if (auth.isNotEmpty) {
        AuthHolder.instance.setAuthorizationHeader(auth);
      }
    }

    final headers = <String, String>{
      if (!multipart) 'Content-Type': 'application/json',
      'x-api-token': apiToken ?? '',
      'Authorization': auth,
    };

    if (kDebugMode && auth.isNotEmpty) {
      debugPrint('[AuthHelper] Providing header: $auth');
    }

    return headers;
  }
}
