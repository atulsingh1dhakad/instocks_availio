// lib/src/repositories/billing_repository.dart
import '../models/inventory_items.dart';
import '../services/billing_service.dart';

class BillingRepository {
  final BillingService service;
  BillingRepository({required this.service});

  Future<List<InventoryItem>> getInventory({required String storeId, required String branch}) =>
      service.fetchInventory(storeId: storeId, branch: branch);

  Future<void> createInvoice({
    required String customerName,
    required dynamic phone,
    required List<Map<String, dynamic>> items,
    required double total,
    required String paymentMode,
    String notes = '',
    String counterId = 'C1',
  }) =>
      service.generateInvoice(customerName: customerName, phone: phone, items: items, total: total, paymentMode: paymentMode, notes: notes, counterId: counterId);
}