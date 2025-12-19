import 'package:image_picker/image_picker.dart';

abstract class ProductEvent {}

class ProductImageUploadRequested extends ProductEvent {
  final XFile file;
  final String apiUrl;
  final String storeId;
  ProductImageUploadRequested({required this.file, required this.apiUrl, required this.storeId});
}

class ProductAddRequested extends ProductEvent {
  final List<Map<String, dynamic>> productsJson;
  final String apiUrl;
  ProductAddRequested({required this.productsJson, required this.apiUrl});
}