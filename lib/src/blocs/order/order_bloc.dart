// lib/src/blocs/order/order_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'order_event.dart';
import 'order_state.dart';
import '../../repositories/order_repository.dart';
import '../../models/order_model.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository repository;

  OrderBloc({required this.repository}) : super(OrdersInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<RefreshOrders>(_onRefreshOrders);
    on<AcceptOrderEvent>(_onAcceptOrder);
    on<RejectOrderEvent>(_onRejectOrder);
  }

  Future<void> _onLoadOrders(LoadOrders event, Emitter<OrderState> emit) async {
    emit(OrdersLoadInProgress());
    try {
      List<OrderModel> orders;
      if (event.status == 'pending') {
        orders = await repository.getPendingOrders(event.storeId, event.branch);
      } else {
        orders = await repository.getOrdersByStatus(event.status, event.storeId, event.branch, page: event.page, limit: event.limit);
      }
      emit(OrdersLoadSuccess(orders));
    } catch (e) {
      emit(OrdersLoadFailure(e.toString()));
    }
  }

  Future<void> _onRefreshOrders(RefreshOrders event, Emitter<OrderState> emit) async {
    // delegate to load
    add(LoadOrders(status: event.status, storeId: event.storeId, branch: event.branch));
  }

  Future<void> _onAcceptOrder(AcceptOrderEvent event, Emitter<OrderState> emit) async {
    emit(OrderActionInProgress());
    try {
      await repository.acceptOrder(event.orderId, event.storeId, event.branch);
      emit(const OrderActionSuccess('Order accepted'));
      // reload orders
      add(LoadOrders(status: 'pending', storeId: event.storeId, branch: event.branch));
    } catch (e) {
      emit(OrderActionFailure(e.toString()));
    }
  }

  Future<void> _onRejectOrder(RejectOrderEvent event, Emitter<OrderState> emit) async {
    emit(OrderActionInProgress());
    try {
      await repository.rejectOrder(event.orderId, event.storeId, event.branch, event.reason);
      emit(const OrderActionSuccess('Order rejected'));
      // reload orders
      add(LoadOrders(status: 'pending', storeId: event.storeId, branch: event.branch));
    } catch (e) {
      emit(OrderActionFailure(e.toString()));
    }
  }
}