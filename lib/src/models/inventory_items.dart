// lib/src/models/inventory_item.dart
class InventoryItem {
  final dynamic id;
  final String name;
  final double price;
  final double quantity;
  final String barcode;
  final dynamic mrp;
  final String? image;
  final String category;
  final Map<String, dynamic> raw;

  InventoryItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.barcode,
    required this.mrp,
    this.image,
    required this.category,
    required this.raw,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final sell = json['sell_price'];
    double sellPrice = 0.0;
    if (sell is List && sell.isNotEmpty) {
      sellPrice = (sell[0] is num) ? (sell[0] as num).toDouble() : double.tryParse(sell[0].toString()) ?? 0.0;
    } else {
      sellPrice = (json['mrp'] is num) ? (json['mrp'] as num).toDouble() : double.tryParse((json['mrp'] ?? '0').toString()) ?? 0.0;
    }

    final qty = json['quantity'];
    double parsedQty = 0.0;
    if (qty is List && qty.isNotEmpty) {
      parsedQty = (qty[0] is num) ? (qty[0] as num).toDouble() : double.tryParse(qty[0].toString()) ?? 0.0;
    } else if (qty is num) {
      parsedQty = (qty).toDouble();
    } else {
      parsedQty = double.tryParse(qty?.toString() ?? '0') ?? 0.0;
    }

    return InventoryItem(
      id: json['product_id'] ?? json['id'] ?? '',
      name: (json['name'] ?? '').toString(),
      price: sellPrice,
      quantity: parsedQty,
      barcode: (json['barcode'] ?? '').toString(),
      mrp: json['mrp'] ?? '',
      image: json['image']?.toString(),
      category: (json['category'] ?? 'Uncategorized').toString(),
      raw: json,
    );
  }
}