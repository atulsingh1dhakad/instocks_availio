// lib/src/blocs/billing/billing_event.dart
import 'package:equatable/equatable.dart';

import '../../models/inventory_items.dart';

abstract class BillingEvent extends Equatable {
  const BillingEvent();
  @override
  List<Object?> get props => [];
}

class LoadInventory extends BillingEvent {
  final String storeId;
  final String branch;
  const LoadInventory({required this.storeId, required this.branch});
  @override
  List<Object?> get props => [storeId, branch];
}

class AddToCart extends BillingEvent {
  final InventoryItem product;
  const AddToCart(this.product);
  @override
  List<Object?> get props => [product];
}

class IncreaseQty extends BillingEvent {
  final dynamic productId;
  const IncreaseQty(this.productId);
  @override
  List<Object?> get props => [productId];
}

class DecreaseQty extends BillingEvent {
  final dynamic productId;
  const DecreaseQty(this.productId);
  @override
  List<Object?> get props => [productId];
}

class RemoveFromCart extends BillingEvent {
  final dynamic productId;
  const RemoveFromCart(this.productId);
  @override
  List<Object?> get props => [productId];
}

class ProceedInvoice extends BillingEvent {
  final String customerName;
  final String customerPhone;
  final String paymentMode;
  const ProceedInvoice({required this.customerName, required this.customerPhone, required this.paymentMode});
  @override
  List<Object?> get props => [customerName, customerPhone, paymentMode];
}