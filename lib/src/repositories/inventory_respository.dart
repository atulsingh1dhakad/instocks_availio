import '../models/category_model.dart';
import '../models/prouduct_model.dart';
import '../services/inventory_service.dart';

class InventoryRepository {
  final InventoryService service;
  InventoryRepository(this.service);

  Future<Map<String, dynamic>> fetchUser() => service.fetchUser();

  Future<List<ProductModel>> fetchInventory(String storeId, String branch) => service.fetchInventory(storeId, branch);

  Future<List<CategoryModel>> fetchCategories() => service.fetchCategories();
}