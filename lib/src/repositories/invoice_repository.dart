// lib/src/repositories/invoice_repository.dart
import '../models/invoice_model.dart';
import '../services/invoice_service.dart';

class InvoiceRepository {
  final InvoiceService service;
  InvoiceRepository({required this.service});

  Future<List<InvoiceModel>> getInvoices({
    required String storeId,
    required String branch,
    int page = 1,
    int limit = 10,
    String? fromDate,
    String? toDate,
  }) =>
      service.fetchInvoices(storeId: storeId, branch: branch, page: page, limit: limit, fromDate: fromDate, toDate: toDate);

  Future<InvoiceModel> getInvoiceDetail(String invoiceId) => service.fetchInvoiceDetail(invoiceId);
}