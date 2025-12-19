// lib/src/models/order_model.dart
class OrderModel {
  final String orderId;
  final String paymentStatus;
  final String orderStatus;
  final dynamic totalAmount;
  final Map<String, dynamic> raw;

  OrderModel({
    required this.orderId,
    required this.paymentStatus,
    required this.orderStatus,
    this.totalAmount,
    required this.raw,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: (json['order_id'] ?? json['id'] ?? '').toString(),
      paymentStatus: (json['payment_status'] ?? '').toString(),
      orderStatus: (json['order_status'] ?? '').toString(),
      totalAmount: json['total_amount'] ?? json['total_price'] ?? '',
      raw: json,
    );
  }

  Map<String, dynamic> toMapForList() {
    return {
      'label': 'Order ID: $orderId',
      'leftStatus': paymentStatus,
      'middle': totalAmount != null ? '₹$totalAmount' : '',
      'rightStatus': orderStatus,
      'order_id': orderId,
      'raw': raw,
    };
  }
}