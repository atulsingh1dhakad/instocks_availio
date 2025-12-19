// lib/src/services/billing_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/auth_helper.dart';
import '../../consts.dart';
import '../models/inventory_items.dart';

class BillingService {
  final String apiUrl;
  final String apiToken;
  BillingService({required this.apiUrl, required this.apiToken});

  Future<List<InventoryItem>> fetchInventory({required String storeId, required String branch}) async {
    final uri = Uri.parse('${apiUrl}products/get-all-product-with-price/?store_id=$storeId&branch=$branch');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200) {
      final body = jsonDecode(resp.body);
      final List<dynamic> rawList = (body is Map && body['products'] is List) ? body['products'] as List : <dynamic>[];
      return rawList.whereType<Map<String, dynamic>>().map((m) => InventoryItem.fromJson(m)).toList();
    }
    throw HttpExceptionWithBody(resp.statusCode, resp.body);
  }

  Future<void> generateInvoice({
    required String customerName,
    required dynamic phone,
    required List<Map<String, dynamic>> items,
    required double total,
    required String paymentMode,
    String notes = '',
    String counterId = 'C1',
  }) async {
    final uri = Uri.parse('${apiUrl}invoices/generate-invoice/');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);
    final body = jsonEncode({
      "date": DateTime.now().toIso8601String(),
      "customer_name": customerName,
      "phone": phone,
      "items": items,
      "total": total,
      "payment_mode": paymentMode,
      "notes": notes,
      "counter_id": counterId,
    });
    final resp = await http.post(uri, headers: headers, body: body);
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw HttpExceptionWithBody(resp.statusCode, resp.body);
    }
  }
}

class HttpExceptionWithBody implements Exception {
  final int statusCode;
  final String body;
  HttpExceptionWithBody(this.statusCode, this.body);
  @override
  String toString() => 'HTTP $statusCode: $body';
}