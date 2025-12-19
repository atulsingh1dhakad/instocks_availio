// lib/src/blocs/recycle/recycle_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/recycle_repository.dart';
import 'RecycleEvent.dart' show RecycleEvent, LoadRecycleBin, RestoreProductEvent, DeleteProductEvent, DeleteAllProductsEvent;
import 'RecycleState.dart';

class RecycleBloc extends Bloc<RecycleEvent, RecycleState> {
  final RecycleRepository repository;

  RecycleBloc({required this.repository}) : super(RecycleInitial()) {
    on<LoadRecycleBin>(_onLoad);
    on<RestoreProductEvent>(_onRestore);
    on<DeleteProductEvent>(_onDelete);
    on<DeleteAllProductsEvent>(_onDeleteAll);
  }

  Future<void> _onLoad(LoadRecycleBin event, Emitter<RecycleState> emit) async {
    emit(RecycleLoadInProgress());
    try {
      final items = await repository.getRecycleBin();
      emit(RecycleLoadSuccess(items));
    } catch (e) {
      emit(RecycleLoadFailure(e.toString()));
    }
  }

  Future<void> _onRestore(RestoreProductEvent event, Emitter<RecycleState> emit) async {
    emit(RecycleActionInProgress());
    try {
      await repository.restore(event.productId);
      emit(const RecycleActionSuccess('Product restored successfully'));
      // reload list
      add(LoadRecycleBin());
    } catch (e) {
      emit(RecycleActionFailure(e.toString()));
      // reload after failure so UI gets consistent state
      add(LoadRecycleBin());
    }
  }

  Future<void> _onDelete(DeleteProductEvent event, Emitter<RecycleState> emit) async {
    emit(RecycleActionInProgress());
    try {
      await repository.delete(event.productId);
      emit(const RecycleActionSuccess('Product permanently deleted'));
      add(LoadRecycleBin());
    } catch (e) {
      emit(RecycleActionFailure(e.toString()));
      add(LoadRecycleBin());
    }
  }

  Future<void> _onDeleteAll(DeleteAllProductsEvent event, Emitter<RecycleState> emit) async {
    emit(RecycleActionInProgress());
    try {
      await repository.deleteAll();
      emit(const RecycleActionSuccess('All products permanently deleted'));
      add(LoadRecycleBin());
    } catch (e) {
      emit(RecycleActionFailure(e.toString()));
      add(LoadRecycleBin());
    }
  }
}