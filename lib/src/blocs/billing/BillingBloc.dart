// lib/src/blocs/billing/billing_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/inventory_items.dart';
import '../../repositories/billing_repository.dart';
import '../../models/cart_item.dart';
import 'BillingEvent.dart';
import 'BillingState.dart';

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final BillingRepository repository;
  BillingBloc({required this.repository}) : super(BillingInitial()) {
    on<LoadInventory>(_onLoadInventory);
    on<AddToCart>(_onAddToCart);
    on<IncreaseQty>(_onIncreaseQty);
    on<DecreaseQty>(_onDecreaseQty);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ProceedInvoice>(_onProceedInvoice);
  }

  Future<void> _onLoadInventory(LoadInventory event, Emitter<BillingState> emit) async {
    emit(BillingLoading());
    try {
      final items = await repository.getInventory(storeId: event.storeId, branch: event.branch);
      emit(BillingLoadSuccess(inventory: items, cart: [], subtotal: 0.0, tax: 0.0, total: 0.0));
    } catch (e) {
      emit(BillingFailure(e.toString()));
    }
  }

  void _recomputeAndEmit(List<InventoryItem> inventory, List<CartItem> cart, Emitter<BillingState> emit) {
    final subtotal = cart.fold<double>(0.0, (s, it) => s + it.lineTotal);
    final tax = subtotal * 0.044; // same example tax as before
    final total = subtotal + tax;
    emit(BillingLoadSuccess(inventory: inventory, cart: cart, subtotal: subtotal, tax: tax, total: total));
  }

  FutureOr<void> _onAddToCart(AddToCart event, Emitter<BillingState> emit) {
    final current = state;
    if (current is BillingLoadSuccess) {
      final inventory = List<InventoryItem>.from(current.inventory);
      final cart = List<CartItem>.from(current.cart);
      final idx = cart.indexWhere((c) => c.product.id == event.product.id);
      if (idx >= 0) {
        cart[idx].qty += 1;
      } else {
        cart.add(CartItem(product: event.product, qty: 1, priceUsed: event.product.price));
      }
      _recomputeAndEmit(inventory, cart, emit);
    }
  }

  FutureOr<void> _onIncreaseQty(IncreaseQty event, Emitter<BillingState> emit) {
    final current = state;
    if (current is BillingLoadSuccess) {
      final inventory = List<InventoryItem>.from(current.inventory);
      final cart = List<CartItem>.from(current.cart);
      final idx = cart.indexWhere((c) => c.product.id == event.productId);
      if (idx >= 0) {
        cart[idx].qty += 1;
      }
      _recomputeAndEmit(inventory, cart, emit);
    }
  }

  FutureOr<void> _onDecreaseQty(DecreaseQty event, Emitter<BillingState> emit) {
    final current = state;
    if (current is BillingLoadSuccess) {
      final inventory = List<InventoryItem>.from(current.inventory);
      final cart = List<CartItem>.from(current.cart);
      final idx = cart.indexWhere((c) => c.product.id == event.productId);
      if (idx >= 0) {
        if (cart[idx].qty > 1) {
          cart[idx].qty -= 1;
        } else {
          cart.removeAt(idx);
        }
      }
      _recomputeAndEmit(inventory, cart, emit);
    }
  }

  FutureOr<void> _onRemoveFromCart(RemoveFromCart event, Emitter<BillingState> emit) {
    final current = state;
    if (current is BillingLoadSuccess) {
      final inventory = List<InventoryItem>.from(current.inventory);
      final cart = List<CartItem>.from(current.cart);
      cart.removeWhere((c) => c.product.id == event.productId);
      _recomputeAndEmit(inventory, cart, emit);
    }
  }

  Future<void> _onProceedInvoice(ProceedInvoice event, Emitter<BillingState> emit) async {
    final current = state;
    if (current is BillingLoadSuccess) {
      if (current.cart.isEmpty) {
        emit(InvoiceFailure('Cart is empty'));
        return;
      }
      emit(InvoiceInProgress());
      try {
        final items = current.cart.map((c) => c.toInvoiceItem()).toList();
        final phoneToSend = event.customerPhone.trim().isEmpty ? 0 : int.tryParse(event.customerPhone.trim()) ?? 0;
        await repository.createInvoice(
          customerName: event.customerName,
          phone: phoneToSend,
          items: items,
          total: current.total,
          paymentMode: event.paymentMode,
        );
        emit(InvoiceSuccess());
        // after success clear cart and keep inventory
        emit(BillingLoadSuccess(inventory: current.inventory, cart: [], subtotal: 0.0, tax: 0.0, total: 0.0));
      } catch (e) {
        emit(InvoiceFailure(e.toString()));
        // restore previous billing success state so UI can continue
        emit(current);
      }
    }
  }
}