class CategoryModel {
  final String id;
  final String name;
  final String description;
  final int categoryId;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['category_name'] ?? json['name'] ?? '').toString(),
      description: (json['category_description'] ?? json['description'] ?? '').toString(),
      categoryId: json['category_id'] is int
          ? json['category_id'] as int
          : (json['category_id'] is String ? int.tryParse(json['category_id']) ?? 0 : 0),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'category_name': name,
    'category_description': description,
    'category_id': categoryId,
  };
}