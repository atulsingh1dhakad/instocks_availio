// lib/src/repositories/order_repository.dart
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderRepository {
  final OrderService service;
  OrderRepository({required this.service});

  Future<List<OrderModel>> getPendingOrders(String storeId, String branch) => service.fetchPendingOrders(storeId: storeId, branch: branch);

  Future<List<OrderModel>> getOrdersByStatus(String status, String storeId, String branch, {int page = 1, int limit = 10}) =>
      service.fetchOrdersByStatus(status: status, storeId: storeId, branch: branch, page: page, limit: limit);

  Future<void> acceptOrder(String orderId, String storeId, String branch) => service.acceptOrder(orderId: orderId, storeId: storeId, branch: branch);

  Future<void> rejectOrder(String orderId, String storeId, String branch, String reason) => service.rejectOrder(orderId: orderId, storeId: storeId, branch: branch, reason: reason);
}