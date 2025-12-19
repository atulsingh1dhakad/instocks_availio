// lib/src/models/invoice_model.dart
class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String date;
  final dynamic subtotal;
  final dynamic tax;
  final dynamic discount;
  final dynamic total;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> raw;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.date,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.items,
    required this.raw,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final id = (json['invoice_number'] ?? json['id'] ?? '').toString();
    final customerName = (json['customer_name'] ?? json['customer'] ?? '').toString();
    final customerEmail = (json['customer_email'] ?? '').toString();
    final customerPhone = (json['customer_phone'] ?? json['phone'] ?? '').toString();
    final date = (json['date'] ?? json['created_at'] ?? '').toString();

    final itemsRaw = json['items'] ?? json['line_items'] ?? json['products'] ?? [];
    final items = <Map<String, dynamic>>[];
    if (itemsRaw is List) {
      for (final it in itemsRaw) {
        if (it is Map<String, dynamic>) items.add(it);
        else items.add({'description': it.toString()});
      }
    }

    return InvoiceModel(
      id: id,
      invoiceNumber: id,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      date: date,
      subtotal: json['subtotal'] ?? json['sub_total'] ?? json['amount_before_tax'] ?? json['amount'] ?? 0,
      tax: json['tax'] ?? json['tax_total'] ?? 0,
      discount: json['discount'] ?? 0,
      total: json['total'] ?? json['grand_total'] ?? json['amount'] ?? 0,
      items: items,
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toListTileMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'date': date,
      'total': total,
      'raw': raw,
    };
  }
}