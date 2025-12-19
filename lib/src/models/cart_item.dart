// lib/src/models/cart_item.dart
import 'inventory_items.dart';

class CartItem {
  final InventoryItem product;
  int qty;
  double priceUsed;

  CartItem({
    required this.product,
    required this.qty,
    required this.priceUsed,
  });

  double get lineTotal => qty * priceUsed;

  Map<String, dynamic> toInvoiceItem() => {
    "product_id": product.id,
    "qty_used": qty,
    "price_used": priceUsed,
  };
}