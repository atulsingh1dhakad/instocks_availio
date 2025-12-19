// lib/src/models/recycle_item.dart
class RecycleItem {
  final int productId;
  final String name;
  final String? description;
  final String? image;
  final String? sku;
  final String? unit;
  final int? barcode;
  final dynamic buyPrice;
  final dynamic sellPrice;
  final List<dynamic>? quantity;
  final Map<String, dynamic> raw;

  RecycleItem({
    required this.productId,
    required this.name,
    this.description,
    this.image,
    this.sku,
    this.unit,
    this.barcode,
    this.buyPrice,
    this.sellPrice,
    this.quantity,
    required this.raw,
  });

  factory RecycleItem.fromJson(Map<String, dynamic> json) {
    int parsedId = 0;
    final dynamic rawId = json['product_id'] ?? json['id'];
    if (rawId is int) parsedId = rawId;
    else if (rawId is String) parsedId = int.tryParse(rawId) ?? 0;
    else if (rawId != null) parsedId = int.tryParse(rawId.toString()) ?? 0;

    int? parsedBarcode;
    final dynamic bar = json['barcode'];
    if (bar is int) parsedBarcode = bar;
    else if (bar is String) parsedBarcode = int.tryParse(bar);

    return RecycleItem(
      productId: parsedId,
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      sku: json['sku']?.toString(),
      unit: json['unit']?.toString(),
      barcode: parsedBarcode,
      buyPrice: json['buy_price'] is List && (json['buy_price'] as List).isNotEmpty ? (json['buy_price'][0]) : json['buy_price'],
      sellPrice: json['sell_price'] is List && (json['sell_price'] as List).isNotEmpty ? (json['sell_price'][0]) : json['sell_price'],
      quantity: json['quantity'] is List ? List<dynamic>.from(json['quantity']) : (json['quantity'] != null ? [json['quantity']] : []),
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toDisplayMap() {
    return {
      'product_id': productId,
      'name': name,
      'description': description,
      'image': image,
      'sku': sku,
      'unit': unit,
      'barcode': barcode,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'quantity': quantity,
    };
  }
}