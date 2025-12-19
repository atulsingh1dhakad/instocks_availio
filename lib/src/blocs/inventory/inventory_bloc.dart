import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/inventory_respository.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryRepository repository;

  InventoryBloc(this.repository) : super(InventoryInitial()) {
    on<InventoryRequested>(_onRequested);
    on<InventoryRefreshed>(_onRefreshed);
  }

  Future<void> _onRequested(InventoryRequested event, Emitter<InventoryState> emit) async {
    emit(InventoryLoadInProgress());
    try {
      final userJson = await repository.fetchUser();
      final String? storeId = userJson['store_id']?.toString();
      final String? branch = userJson['branch']?.toString();
      if (storeId == null || branch == null) {
        emit(InventoryLoadFailure("User's store_id or branch missing"));
        return;
      }
      final products = await repository.fetchInventory(storeId, branch);
      final categories = await repository.fetchCategories();
      emit(InventoryLoadSuccess(products: products, categories: categories, storeId: storeId, branch: branch));
    } catch (e) {
      emit(InventoryLoadFailure(e.toString()));
    }
  }

  Future<void> _onRefreshed(InventoryRefreshed event, Emitter<InventoryState> emit) async {
    // keep previous state while refreshing, but show progress first
    emit(InventoryLoadInProgress());
    try {
      final userJson = await repository.fetchUser();
      final String? storeId = userJson['store_id']?.toString();
      final String? branch = userJson['branch']?.toString();
      if (storeId == null || branch == null) {
        emit(InventoryLoadFailure("User's store_id or branch missing"));
        return;
      }
      final products = await repository.fetchInventory(storeId, branch);
      final categories = await repository.fetchCategories();
      emit(InventoryLoadSuccess(products: products, categories: categories, storeId: storeId, branch: branch));
    } catch (e) {
      emit(InventoryLoadFailure(e.toString()));
    }
  }
}