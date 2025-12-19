// lib/src/ui/recycle_card.dart
import 'package:flutter/material.dart';
import '../models/recycle_item.dart';

class RecycleCard extends StatelessWidget {
  final RecycleItem item;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const RecycleCard({super.key, required this.item, required this.onRestore, required this.onDelete});

  Widget _metricBox(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Colors.grey[100], border: Border.all(color: Colors.grey.shade300)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)), Text(value == null ? "" : value.toString(), style: const TextStyle(fontSize: 10))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    item.image ?? "https://www.pngall.com/wp-content/uploads/8/Sample.png",
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], height: 50, width: 50, child: const Icon(Icons.image, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(item.description ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      _metricBox("Unit", item.unit),
                      _metricBox("SKU", item.sku),
                      _metricBox("Barcode", item.barcode),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      _metricBox("Buy", item.buyPrice),
                      const SizedBox(width: 6),
                      _metricBox("Sell", item.sellPrice),
                      const SizedBox(width: 6),
                      _metricBox("Qty", item.quantity != null && item.quantity!.isNotEmpty ? item.quantity![0] : ""),
                    ]),
                  ]),
                ),
                const SizedBox(width: 8),
                Column(children: [
                  IconButton(icon: const Icon(Icons.restore, color: Colors.green), tooltip: "Restore", onPressed: onRestore),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), tooltip: "Delete", onPressed: onDelete),
                ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}