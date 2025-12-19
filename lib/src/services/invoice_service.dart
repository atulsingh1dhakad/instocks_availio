// lib/src/services/invoice_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/auth_helper.dart';
import '../models/invoice_model.dart';
import '../../consts.dart';

class InvoiceService {
  final String apiUrl;
  final String apiToken;

  InvoiceService({required this.apiUrl, required this.apiToken});

  /// Fetch invoices for store/branch with optional filters and pagination.
  Future<List<InvoiceModel>> fetchInvoices({
    required String storeId,
    required String branch,
    int page = 1,
    int limit = 10,
    String? fromDate,
    String? toDate,
  }) async {
    final uri = Uri.parse('${apiUrl}invoices/store-invoices');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);
    final body = {
      'store_id': storeId,
      'branch': branch,
      'page': page,
      'limit': limit,
      if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
    };
    final resp = await http.post(uri, headers: headers, body: jsonEncode(body));
    if (resp.statusCode == 200) {
      final parsed = jsonDecode(resp.body);
      final rawList = (parsed is Map && parsed['invoices'] is List) ? parsed['invoices'] as List : (parsed is List ? parsed : <dynamic>[]);
      final invoices = <InvoiceModel>[];
      for (final it in rawList) {
        if (it is Map<String, dynamic>) invoices.add(InvoiceModel.fromJson(it));
      }
      return invoices;
    }
    throw HttpExceptionWithBody(resp.statusCode, resp.body);
  }

  /// Optionally fetch a single invoice detail (if your API supports it).
  Future<InvoiceModel> fetchInvoiceDetail(String invoiceId) async {
    final uri = Uri.parse('${apiUrl}invoices/$invoiceId');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      if (body is Map<String, dynamic>) return InvoiceModel.fromJson(body);
    }
    throw HttpExceptionWithBody(resp.statusCode, resp.body);
  }
}

class HttpExceptionWithBody implements Exception {
  final int code;
  final String body;
  HttpExceptionWithBody(this.code, this.body);

  @override
  String toString() => 'HTTP $code: $body';
}