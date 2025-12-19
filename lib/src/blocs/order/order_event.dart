// lib/src/blocs/order/order_event.dart
import 'package:equatable/equatable.dart';

abstract class OrderEvent extends Equatable {
  const OrderEvent();
  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrderEvent {
  final String status;
  final int page;
  final int limit;
  final String storeId;
  final String branch;

  const LoadOrders({required this.status, required this.storeId, required this.branch, this.page = 1, this.limit = 10});

  @override
  List<Object?> get props => [status, page, limit, storeId, branch];
}

class RefreshOrders extends OrderEvent {
  final String status;
  final String storeId;
  final String branch;
  const RefreshOrders({required this.status, required this.storeId, required this.branch});
  @override
  List<Object?> get props => [status, storeId, branch];
}

class AcceptOrderEvent extends OrderEvent {
  final String orderId;
  final String storeId;
  final String branch;
  const AcceptOrderEvent({required this.orderId, required this.storeId, required this.branch});
  @override
  List<Object?> get props => [orderId, storeId, branch];
}

class RejectOrderEvent extends OrderEvent {
  final String orderId;
  final String storeId;
  final String branch;
  final String reason;
  const RejectOrderEvent({required this.orderId, required this.storeId, required this.branch, required this.reason});
  @override
  List<Object?> get props => [orderId, storeId, branch, reason];
}