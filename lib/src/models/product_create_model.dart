class ProductCreate {
  final String name;
  final int categoryId;
  final bool onlineVisibility;
  final double mrp;
  final List<double> buyPrice;
  final List<double> sellPrice;
  final double onlineSellPrice;
  final List<int> quantity;
  final String storeId;
  final String branch;
  final String unit;
  final int barcode;
  final String description;
  final String sku;
  final String? productImageUrl;

  ProductCreate({
    required this.name,
    required this.categoryId,
    required this.onlineVisibility,
    required this.mrp,
    required this.buyPrice,
    required this.sellPrice,
    required this.onlineSellPrice,
    required this.quantity,
    required this.storeId,
    required this.branch,
    required this.unit,
    required this.barcode,
    required this.description,
    required this.sku,
    this.productImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "category": categoryId,
      "online_visibility": onlineVisibility,
      "mrp": mrp,
      "buy_price": buyPrice,
      "sell_price": sellPrice,
      "online_sell_price": onlineSellPrice,
      "quantity": quantity,
      "store_id": storeId,
      "branch": branch,
      "unit": unit,
      "barcode": barcode,
      "description": description,
      "sku": sku,
      if (productImageUrl != null && productImageUrl!.isNotEmpty) "product_image": {"url": productImageUrl},
    };
  }
}