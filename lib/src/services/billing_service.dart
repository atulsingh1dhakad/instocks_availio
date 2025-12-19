// lib/src/services/billing_service.dart
import 'dart:convert';
import '../models/inventory_items.dart';
import 'api_client.dart';
import '../../consts.dart';

class BillingService {
  final ApiClient _client;

  BillingService({ApiClient? client}) 
      : _client = client ?? ApiClient(baseUrl: API_URL);

  Future<List<InventoryItem>> fetchInventory({required String storeId, required String branch}) async {
    final resp = await _client.get('products/get-all-product-with-price/?store_id=$storeId&branch=$branch');
    final body = jsonDecode(resp.body);
    final List<dynamic> rawList = (body is Map && body['products'] is List) ? body['products'] as List : <dynamic>[];
    return rawList.whereType<Map<String, dynamic>>().map((m) => InventoryItem.fromJson(m)).toList();
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
    final body = {
      "date": DateTime.now().toIso8601String(),
      "customer_name": customerName,
      "phone": phone,
      "items": items,
      "total": total,
      "payment_mode": paymentMode,
      "notes": notes,
      "counter_id": counterId,
    };
    await _client.post('invoices/generate-invoice/', body: body);
  }
}
