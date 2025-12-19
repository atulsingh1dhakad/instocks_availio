import '../../models/category_model.dart';
import '../../models/prouduct_model.dart';

abstract class InventoryState {}

class InventoryInitial extends InventoryState {}

class InventoryLoadInProgress extends InventoryState {}

class InventoryLoadSuccess extends InventoryState {
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final String storeId;
  final String branch;

  InventoryLoadSuccess({
    required this.products,
    required this.categories,
    required this.storeId,
    required this.branch,
  });
}

class InventoryLoadFailure extends InventoryState {
  final String message;
  InventoryLoadFailure(this.message);
}