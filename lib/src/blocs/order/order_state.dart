// lib/src/blocs/order/order_state.dart
import 'package:equatable/equatable.dart';
import '../../models/order_model.dart';

abstract class OrderState extends Equatable {
  const OrderState();
  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrderState {}

class OrdersLoadInProgress extends OrderState {}

class OrdersLoadSuccess extends OrderState {
  final List<OrderModel> orders;
  const OrdersLoadSuccess(this.orders);
  @override
  List<Object?> get props => [orders];
}

class OrdersLoadFailure extends OrderState {
  final String message;
  const OrdersLoadFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class OrderActionInProgress extends OrderState {}

class OrderActionSuccess extends OrderState {
  final String message;
  const OrderActionSuccess([this.message = 'Success']);
  @override
  List<Object?> get props => [message];
}

class OrderActionFailure extends OrderState {
  final String message;
  const OrderActionFailure(this.message);
  @override
  List<Object?> get props => [message];
}