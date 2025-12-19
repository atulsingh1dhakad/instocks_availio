// lib/src/blocs/recycle/recycle_state.dart
import 'package:equatable/equatable.dart';
import '../../models/recycle_item.dart';

abstract class RecycleState extends Equatable {
  const RecycleState();
  @override
  List<Object?> get props => [];
}

class RecycleInitial extends RecycleState {}

class RecycleLoadInProgress extends RecycleState {}

class RecycleLoadSuccess extends RecycleState {
  final List<RecycleItem> items;
  const RecycleLoadSuccess(this.items);
  @override
  List<Object?> get props => [items];
}

class RecycleLoadFailure extends RecycleState {
  final String message;
  const RecycleLoadFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class RecycleActionInProgress extends RecycleState {}

class RecycleActionSuccess extends RecycleState {
  final String message;
  const RecycleActionSuccess([this.message = 'Success']);
  @override
  List<Object?> get props => [message];
}

class RecycleActionFailure extends RecycleState {
  final String message;
  const RecycleActionFailure(this.message);
  @override
  List<Object?> get props => [message];
}