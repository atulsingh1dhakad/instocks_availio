abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductImageUploadInProgress extends ProductState {}

class ProductImageUploadSuccess extends ProductState {
  final String imageUrl;
  ProductImageUploadSuccess(this.imageUrl);
}

class ProductImageUploadFailure extends ProductState {
  final String message;
  ProductImageUploadFailure(this.message);
}

class ProductAddInProgress extends ProductState {}

class ProductAddSuccess extends ProductState {}

class ProductAddFailure extends ProductState {
  final String message;
  ProductAddFailure(this.message);
}