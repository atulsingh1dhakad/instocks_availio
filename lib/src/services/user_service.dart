// lib/src/services/user_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../helpers/auth_helper.dart';
import '../models/user_profile.dart';

class UserService {
  final String apiUrl;
  final String apiToken;

  UserService({required this.apiUrl, required this.apiToken});

  /// Fetches the current user's profile from the backend, saves it to SharedPreferences,
  /// and returns a UserProfile.
  Future<UserProfile> fetchProfile() async {
    final uri = Uri.parse('${apiUrl}users/me');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);

    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      if (body is Map<String, dynamic>) {
        // Persist full payload to prefs for other parts of app
        final prefs = await SharedPreferences.getInstance();
        for (final entry in body.entries) {
          final k = entry.key;
          final v = entry.value;
          if (v is String) {
            await prefs.setString(k, v);
          } else if (v is int) {
            await prefs.setInt(k, v);
          } else if (v is double) {
            await prefs.setDouble(k, v);
          } else if (v is bool) {
            await prefs.setBool(k, v);
          } else if (v is List || v is Map) {
            await prefs.setString(k, jsonEncode(v));
          } else if (v == null) {
            await prefs.remove(k);
          } else {
            await prefs.setString(k, v.toString());
          }
        }
        return UserProfile.fromJson(body);
      } else {
        throw Exception('Unexpected response shape for profile');
      }
    } else {
      // try to extract a useful message
      String message = resp.body;
      try {
        final parsed = jsonDecode(resp.body);
        if (parsed is Map && (parsed['detail'] ?? parsed['message']) != null) {
          message = (parsed['detail'] ?? parsed['message']).toString();
        }
      } catch (_) {}
      throw Exception('Failed to load profile: ${resp.statusCode} - $message');
    }
  }
}