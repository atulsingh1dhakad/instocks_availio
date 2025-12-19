// lib/src/ui/product_tile.dart
import 'package:flutter/material.dart';
import '../models/inventory_items.dart';

class ProductTile extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;

  const ProductTile({super.key, required this.item, required this.onTap});

  Color _categoryColor(String? category) {
    switch (category) {
      case 'Drink':
        return Colors.blue;
      case 'Food':
        return Colors.deepPurple;
      case 'Breakfast':
        return Colors.brown;
      case 'Salad':
        return Colors.orange;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Container(
              height: 36,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _categoryColor(item.category),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Center(
                child: Text(item.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: item.image != null
                  ? Image.network(item.image!, height: 48, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 48, color: Colors.grey))
                  : const Icon(Icons.fastfood, size: 48, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Text(item.price.toStringAsFixed(2), style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ),
          ],
        ),
      ),
    );
  }
}