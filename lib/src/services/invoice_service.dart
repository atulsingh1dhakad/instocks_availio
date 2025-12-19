// lib/src/services/invoice_service.dart
import 'dart:convert';
import '../models/invoice_model.dart';
import 'api_client.dart';
import '../../consts.dart';

class InvoiceService {
  final ApiClient _client;

  InvoiceService({ApiClient? client}) 
      : _client = client ?? ApiClient(baseUrl: API_URL);

  Future<List<InvoiceModel>> fetchInvoices({
    required String storeId,
    required String branch,
    int page = 1,
    int limit = 10,
    String? fromDate,
    String? toDate,
  }) async {
    final body = {
      'store_id': storeId,
      'branch': branch,
      'page': page,
      'limit': limit,
      if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
    };
    final resp = await _client.post('invoices/store-invoices', body: body);
    final parsed = jsonDecode(resp.body);
    final rawList = (parsed is Map && parsed['invoices'] is List) ? parsed['invoices'] as List : (parsed is List ? parsed : <dynamic>[]);
    final invoices = <InvoiceModel>[];
    for (final it in rawList) {
      if (it is Map<String, dynamic>) invoices.add(InvoiceModel.fromJson(it));
    }
    return invoices;
  }

  Future<InvoiceModel> fetchInvoiceDetail(String invoiceId) async {
    final resp = await _client.get('invoices/$invoiceId');
    final body = jsonDecode(resp.body);
    return InvoiceModel.fromJson(body as Map<String, dynamic>);
  }
}
