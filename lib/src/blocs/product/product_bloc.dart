import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/product_repository.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;

  ProductBloc(this.repository) : super(ProductInitial()) {
    on<ProductImageUploadRequested>(_onImageUpload);
    on<ProductAddRequested>(_onAddProducts);
  }

  Future<void> _onImageUpload(ProductImageUploadRequested event, Emitter<ProductState> emit) async {
    emit(ProductImageUploadInProgress());
    try {
      final url = await repository.uploadImage(file: event.file, apiUrl: event.apiUrl, storeId: event.storeId);
      emit(ProductImageUploadSuccess(url));
    } catch (e) {
      emit(ProductImageUploadFailure(e.toString()));
    }
  }

  Future<void> _onAddProducts(ProductAddRequested event, Emitter<ProductState> emit) async {
    emit(ProductAddInProgress());
    try {
      await repository.addProducts(productsJson: event.productsJson, apiUrl: event.apiUrl);
      emit(ProductAddSuccess());
    } catch (e) {
      emit(ProductAddFailure(e.toString()));
    }
  }
}