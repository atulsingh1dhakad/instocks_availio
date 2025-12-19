// lib/src/repositories/recycle_repository.dart
import '../models/recycle_item.dart';
import '../services/recycle_service.dart';

class RecycleRepository {
  final RecycleService service;
  RecycleRepository({required this.service});

  Future<List<RecycleItem>> getRecycleBin() => service.fetchRecycleBin();

  Future<void> restore(int productId) => service.restoreProduct(productId);

  Future<void> delete(int productId) => service.deleteProduct(productId);

  Future<void> deleteAll() => service.deleteAll();
}