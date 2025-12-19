// lib/src/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../consts.dart'; // import API_TOKEN and API_URL
import '../helpers/login_auth_holder.dart';

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);
  @override
  String toString() => 'API Error $statusCode: $body';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.statusCode, super.body);
}

class ApiClient {
  // Static hardcoded token from consts.dart
  static const String staticApiToken = API_TOKEN;
  final String baseUrl;

  ApiClient({required this.baseUrl});

  Uri _uri(String path) {
    if (path.startsWith('http')) return Uri.parse(path);
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final cleanBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse('$cleanBase$cleanPath');
  }

  Map<String, String> _buildHeaders({bool multipart = false, Map<String, String>? extra}) {
    final headers = <String, String>{};
    if (!multipart) headers['Content-Type'] = 'application/json';
    
    // Always use the hardcoded static token for x-api-token
    headers['x-api-token'] = staticApiToken;

    // Dynamically pull the User Authorization (Bearer) token from AuthHolder (backed by SharedPreferences/Cache)
    final authHeader = AuthHolder.instance.authorizationHeader;
    if (authHeader.isNotEmpty) {
      headers['Authorization'] = authHeader; // This sends the FULL UNTRIMMED token
    }

    if (extra != null) headers.addAll(extra);

    if (kDebugMode) {
      // Log the full value so you can see nothing is trimmed
      debugPrint('ApiClient - Outgoing Authorization Header: $authHeader');
    }
    return headers;
  }

  Future<http.Response> get(String path, {Map<String, String>? extraHeaders}) async {
    final uri = _uri(path);
    final headers = _buildHeaders(extra: extraHeaders);
    final resp = await http.get(uri, headers: headers);
    return _handleResponse(resp);
  }

  Future<http.Response> post(String path, {Object? body, bool multipart = false, Map<String, String>? extraHeaders}) async {
    final uri = _uri(path);
    final headers = _buildHeaders(multipart: multipart, extra: extraHeaders);
    final resp = await http.post(uri, headers: headers, body: body is String ? body : jsonEncode(body));
    return _handleResponse(resp);
  }

  Future<http.Response> put(String path, {Object? body, Map<String, String>? extraHeaders}) async {
    final uri = _uri(path);
    final headers = _buildHeaders(extra: extraHeaders);
    final resp = await http.put(uri, headers: headers, body: body is String ? body : jsonEncode(body));
    return _handleResponse(resp);
  }

  Future<http.Response> delete(String path, {Object? body, Map<String, String>? extraHeaders}) async {
    final uri = _uri(path);
    final headers = _buildHeaders(extra: extraHeaders);
    final resp = await http.delete(uri, headers: headers, body: body is String ? body : jsonEncode(body));
    return _handleResponse(resp);
  }

  http.Response _handleResponse(http.Response resp) {
    if (resp.statusCode == 401) {
      throw UnauthorizedException(resp.statusCode, resp.body);
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(resp.statusCode, resp.body);
    }
    return resp;
  }
}
