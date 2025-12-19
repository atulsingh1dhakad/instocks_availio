// lib/src/ui/invoice_card.dart
import 'package:flutter/material.dart';
import '../models/invoice_model.dart';

class InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback? onTap;

  const InvoiceCard({super.key, required this.invoice, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        title: Text('Invoice #${invoice.invoiceNumber}'),
        subtitle: Text('Customer: ${invoice.customerName}\nDate: ${invoice.date}\nTotal: ${invoice.total}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}