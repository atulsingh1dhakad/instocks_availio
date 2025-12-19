import '../models/product_create_model.dart';
import '../services/product_service.dart';
import 'package:image_picker/image_picker.dart';

class ProductRepository {
  final ProductService service;
  ProductRepository(this.service);

  Future<String> uploadImage({required XFile file, required String apiUrl, required String storeId}) =>
      service.uploadProductImage(file: file, apiUrl: apiUrl, storeId: storeId);

  Future<void> addProducts({required List<Map<String, dynamic>> productsJson, required String apiUrl}) =>
      service.addProducts(productsJson: productsJson, apiUrl: apiUrl);

  Future<void> addProduct({required ProductCreate product, required String apiUrl}) =>
      service.addProduct(product: product, apiUrl: apiUrl);
}