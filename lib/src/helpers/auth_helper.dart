// lib/src/helpers/auth_helper.dart
import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  /// Returns headers including x-api-token and Authorization.
  static Future<Map<String, String>> getAuthHeaders({String? apiToken, bool multipart = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('access_token');
    final String tokenTypeRaw = prefs.getString('token_type') ?? 'Bearer';
    final String tokenType = (tokenTypeRaw).trim().isEmpty ? 'Bearer' : tokenTypeRaw.trim();
    final String authorizationHeader = '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} ${accessToken ?? ""}';

    final headers = <String, String>{
      if (!multipart) 'Content-Type': 'application/json',
      'x-api-token': apiToken ?? '',
      'Authorization': authorizationHeader,
    };

    return headers;
  }
}