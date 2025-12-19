class ProductModel {
  final String id;
  final String name;
  final String description;
  final String? image;
  final List<dynamic>? buyPrice;
  final List<dynamic>? sellPrice;
  final List<dynamic>? quantity;
  final int? category;
  final String? unit;
  final String? sku;
  final int? productId;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    this.image,
    this.buyPrice,
    this.sellPrice,
    this.quantity,
    this.category,
    this.unit,
    this.sku,
    this.productId,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['product_name'] ?? '').toString(),
      description: (json['description'] ?? json['product_description'] ?? '').toString(),
      image: (json['image'] ?? json['images'] ?? null) is String ? (json['image'] ?? json['images']) as String : null,
      buyPrice: json['buy_price'] is List ? List<dynamic>.from(json['buy_price']) : (json['buy_price'] != null ? [json['buy_price']] : null),
      sellPrice: json['sell_price'] is List ? List<dynamic>.from(json['sell_price']) : (json['sell_price'] != null ? [json['sell_price']] : null),
      quantity: json['quantity'] is List ? List<dynamic>.from(json['quantity']) : (json['quantity'] != null ? [json['quantity']] : null),
      category: (json['category'] is int) ? json['category'] as int : (json['category'] is String ? int.tryParse(json['category']) : null),
      unit: json['unit']?.toString(),
      sku: json['sku']?.toString(),
      productId: json['product_id'] is int ? json['product_id'] as int : (json['product_id'] is String ? int.tryParse(json['product_id']) : null),
    );
  }
}