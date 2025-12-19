// lib/src/blocs/billing/billing_state.dart
import 'package:equatable/equatable.dart';
import '../../models/cart_item.dart';
import '../../models/inventory_items.dart';

abstract class BillingState extends Equatable {
  const BillingState();
  @override
  List<Object?> get props => [];
}

class BillingInitial extends BillingState {}

class BillingLoading extends BillingState {}

class BillingLoadSuccess extends BillingState {
  final List<InventoryItem> inventory;
  final List<CartItem> cart;
  final double subtotal;
  final double tax;
  final double total;

  const BillingLoadSuccess({
    required this.inventory,
    required this.cart,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  @override
  List<Object?> get props => [inventory, cart, subtotal, tax, total];

  BillingLoadSuccess copyWith({
    List<InventoryItem>? inventory,
    List<CartItem>? cart,
    double? subtotal,
    double? tax,
    double? total,
  }) {
    return BillingLoadSuccess(
      inventory: inventory ?? this.inventory,
      cart: cart ?? this.cart,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
    );
  }
}

class BillingFailure extends BillingState {
  final String message;
  const BillingFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class InvoiceInProgress extends BillingState {}

class InvoiceSuccess extends BillingState {}

class InvoiceFailure extends BillingState {
  final String message;
  const InvoiceFailure(this.message);
  @override
  List<Object?> get props => [message];
}