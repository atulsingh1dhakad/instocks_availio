// lib/src/blocs/recycle/recycle_event.dart
import 'package:equatable/equatable.dart';

abstract class RecycleEvent extends Equatable {
  const RecycleEvent();
  @override
  List<Object?> get props => [];
}

class LoadRecycleBin extends RecycleEvent {}

class RestoreProductEvent extends RecycleEvent {
  final int productId;
  const RestoreProductEvent(this.productId);
  @override
  List<Object?> get props => [productId];
}

class DeleteProductEvent extends RecycleEvent {
  final int productId;
  const DeleteProductEvent(this.productId);
  @override
  List<Object?> get props => [productId];
}

class DeleteAllProductsEvent extends RecycleEvent {}