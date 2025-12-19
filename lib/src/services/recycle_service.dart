// lib/src/services/recycle_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/auth_helper.dart';
import '../models/recycle_item.dart';

class RecycleService {
  final String apiUrl;
  final String apiToken;

  RecycleService({required this.apiUrl, required this.apiToken});

  Future<List<RecycleItem>> fetchRecycleBin() async {
    final uri = Uri.parse('${apiUrl}products/recycle-bin');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      List<dynamic> rawList = [];
      if (body is List) rawList = body;
      else if (body is Map && body['products'] is List) rawList = body['products'];
      else if (body is Map && body['data'] is List) rawList = body['data'];
      return rawList.whereType<Map<String, dynamic>>().map((m) => RecycleItem.fromJson(m)).toList();
    }
    throw HttpExceptionWithBody(resp.statusCode, resp.body);
  }

  Future<void> restoreProduct(int productId) async {
    final uri = Uri.parse('${apiUrl}products/undel-prod');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);
    final resp = await http.post(uri, headers: headers, body: jsonEncode({"product_id": productId}));
    if (resp.statusCode != 200) throw HttpExceptionWithBody(resp.statusCode, resp.body);
  }

  Future<void> deleteProduct(int productId) async {
    final uri = Uri.parse('${apiUrl}products/per-del-prod');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);
    final resp = await http.delete(uri, headers: headers, body: jsonEncode({"product_id": productId}));
    if (resp.statusCode != 200) throw HttpExceptionWithBody(resp.statusCode, resp.body);
  }

  Future<void> deleteAll() async {
    final uri = Uri.parse('${apiUrl}products/per-del-all-prod');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);
    final resp = await http.delete(uri, headers: headers);
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