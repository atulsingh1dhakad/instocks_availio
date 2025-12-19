// lib/src/services/staff_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/auth_helper.dart';
import '../models/staff_model.dart';

class StaffService {
  final String apiUrl;
  final String apiToken;

  StaffService({required this.apiUrl, required this.apiToken});

  Future<List<StaffModel>> fetchStaff() async {
    final uri = Uri.parse('${apiUrl}store/store-employee-details');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      List<dynamic> raw = [];
      if (body is List) raw = body;
      else if (body is Map && body['data'] is List) raw = body['data'];
      else if (body is Map && body['employees'] is List) raw = body['employees'];
      return raw.whereType<Map<String, dynamic>>().map((m) => StaffModel.fromJson(m)).toList();
    }
    throw HttpExceptionWithBody(resp.statusCode, resp.body);
  }

  Future<void> createStaff(Map<String, dynamic> payload) async {
    final uri = Uri.parse('${apiUrl}users/create-fresh-user');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);
    final resp = await http.post(uri, headers: headers, body: jsonEncode(payload));
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw HttpExceptionWithBody(resp.statusCode, resp.body);
    }
  }

  Future<void> deleteStaff(String userId) async {
    final uri = Uri.parse('${apiUrl}users/delete-user');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);
    final resp = await http.post(uri, headers: headers, body: jsonEncode({'user_id': userId}));
    if (resp.statusCode != 200) throw HttpExceptionWithBody(resp.statusCode, resp.body);
  }
}

class HttpExceptionWithBody implements Exception {
  final int statusCode;
  final String body;
  HttpExceptionWithBody(this.statusCode, this.body);
  @override
  String toString() => 'HTTP $statusCode: $body';
}