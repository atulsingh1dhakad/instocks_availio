// lib/src/screens/addnewproduct.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../consts.dart';
import '../models/category_model.dart';
import '../repositories/product_repository.dart';
import '../services/product_service.dart';
import '../blocs/product/product_bloc.dart';
import '../blocs/product/product_event.dart';
import '../blocs/product/product_state.dart';
import '../ui/add_product_skeleton.dart';

class AddNewProductScreen extends StatefulWidget {
  final String? storeId;
  final String? branch;
  final List<CategoryModel> categories; // seeded from parent if available
  final String apiUrl;
  final String apiToken;
  final Future<void> Function()? fetchInventoryCallback;

  const AddNewProductScreen({
    Key? key,
    required this.storeId,
    required this.branch,
    required this.categories,
    required this.apiUrl,
    required this.apiToken,
    this.fetchInventoryCallback,
  }) : super(key: key);

  @override
  State<AddNewProductScreen> createState() => _AddNewProductScreenState();
}

class _AddNewProductScreenState extends State<AddNewProductScreen> {
  // controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController mrpController = TextEditingController();
  final TextEditingController buyPriceController = TextEditingController();
  final TextEditingController sellPriceController = TextEditingController();
  final TextEditingController onlineSellPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();

  // Category handling: keep primitive id and model in sync to avoid Dropdown equality issues
  CategoryModel? selectedCategory;
  int? selectedCategoryId;

  // Local categories store (seeded from widget.categories, updated from backend)
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = false;
  String? _categoriesError;

  bool _isAddingProduct = false;
  bool onlineVisibility = true;

  XFile? _pickedImageWeb;
  File? _pickedImageMobile;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  final List<String> _units = ['KG', 'GM', 'Liter', 'Mililiter', 'Nos'];
  String? selectedUnit;

  List<Map<String, dynamic>> _localProducts = [];

  late final ProductBloc _productBloc;

  @override
  void initState() {
    super.initState();

    // Seed categories from parent so UI is usable immediately
    _categories = List<CategoryModel>.from(widget.categories);
    if (_categories.isNotEmpty) {
      selectedCategory = _categories[0];
      selectedCategoryId = selectedCategory!.categoryId;
    } else {
      selectedCategory = null;
      selectedCategoryId = null;
    }

    selectedUnit = _units[0];

    // Create repository + bloc locally (or inject from main if you prefer)
    final repo = ProductRepository(ProductService());
    _productBloc = ProductBloc(repo);

    // Fetch latest categories from backend (keeps behavior similar to your reference project).
    // We do this inside this widget (not via product bloc) because categories are a separate resource.
    _fetchCategories();
  }

  @override
  void dispose() {
    _productBloc.close();
    nameController.dispose();
    descriptionController.dispose();
    mrpController.dispose();
    buyPriceController.dispose();
    sellPriceController.dispose();
    onlineSellPriceController.dispose();
    quantityController.dispose();
    skuController.dispose();
    barcodeController.dispose();
    super.dispose();
  }

  // Helper to ensure Dropdown's value exists in the list items
  int? get _dropdownValue {
    if (selectedCategoryId == null) return null;
    final exists = _categories.any((c) => c.categoryId == selectedCategoryId);
    return exists ? selectedCategoryId : null;
  }

  Future<Map<String, String>> _getAuthHeaders({bool multipart = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('access_token');
    final String tokenTypeRaw = prefs.getString('token_type') ?? 'Bearer';
    final String tokenType = (tokenTypeRaw).trim().isEmpty ? 'Bearer' : tokenTypeRaw.trim();
    final String authorizationHeader = '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} ${accessToken ?? ""}';

    return {
      if (!multipart) 'Content-Type': 'application/json',
      X_api_token: widget.apiToken,
      'Authorization': authorizationHeader,
    };
  }

  // Fetch categories from backend and update _categories
  // Adjust endpoint path if your backend uses a different route for categories.
  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoriesError = null;
    });

    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('${widget.apiUrl}category'); // adjust if needed
      final resp = await http.get(uri, headers: headers);

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);

        List<dynamic> rawList = [];
        if (body is List) {
          rawList = body;
        } else if (body is Map && body['data'] is List) {
          rawList = body['data'];
        } else if (body is Map && body['categories'] is List) {
          rawList = body['categories'];
        } else {
          // Unexpected shape: leave rawList empty and set error
          rawList = [];
        }

        final fetched = <CategoryModel>[];
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            final dynamic rawCatId = item['categoryId'] ?? item['category_id'] ?? item['id'];
            int parsedCatId = 0;
            if (rawCatId is int) {
              parsedCatId = rawCatId;
            } else if (rawCatId is String) {
              parsedCatId = int.tryParse(rawCatId) ?? 0;
            } else if (rawCatId != null) {
              parsedCatId = int.tryParse(rawCatId.toString()) ?? 0;
            }

            final String idString = (item['id'] ?? parsedCatId ?? '').toString();
            final String name = (item['name'] ?? item['category_name'] ?? item['title'] ?? '').toString();
            final String description = (item['description'] ?? item['desc'] ?? '').toString();

            fetched.add(CategoryModel(id: idString, name: name, description: description, categoryId: parsedCatId));
          }
        }

        setState(() {
          if (fetched.isNotEmpty) {
            _categories = fetched;
            // Keep selection consistent if possible
            if (_categories.any((c) => c.categoryId == selectedCategoryId)) {
              selectedCategory = _categories.firstWhere((c) => c.categoryId == selectedCategoryId);
            } else {
              selectedCategory = _categories.isNotEmpty ? _categories[0] : null;
              selectedCategoryId = selectedCategory?.categoryId;
            }
          }
        });
      } else {
        setState(() {
          _categoriesError = 'Failed to load categories: ${resp.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _categoriesError = 'Error loading categories: $e';
      });
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isUploadingImage = true);

    // store local preview
    if (kIsWeb) {
      _pickedImageWeb = picked;
      _pickedImageMobile = null;
    } else {
      _pickedImageMobile = File(picked.path);
      _pickedImageWeb = null;
    }

    // dispatch upload event via product bloc
    _productBloc.add(ProductImageUploadRequested(file: picked, apiUrl: widget.apiUrl, storeId: widget.storeId ?? ''));

    // Listen once for result.
    late StreamSubscription sub;
    sub = _productBloc.stream.listen((state) async {
      if (state is ProductImageUploadSuccess) {
        setState(() {
          _uploadedImageUrl = state.imageUrl;
          _isUploadingImage = false;
        });
        await sub.cancel();
      } else if (state is ProductImageUploadFailure) {
        setState(() {
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${state.message}')));
        await sub.cancel();
      }
    });
  }

  void _addProductToList() {
    final mrp = double.tryParse(mrpController.text) ?? 0.0;
    final buyPrice = double.tryParse(buyPriceController.text) ?? 0.0;
    final sellPrice = double.tryParse(sellPriceController.text) ?? 0.0;
    final onlineSellPrice = double.tryParse(onlineSellPriceController.text) ?? 0.0;
    final quantity = int.tryParse(quantityController.text) ?? 1;

    if (nameController.text.isNotEmpty &&
        buyPriceController.text.isNotEmpty &&
        sellPriceController.text.isNotEmpty &&
        onlineSellPriceController.text.isNotEmpty &&
        quantityController.text.isNotEmpty &&
        selectedCategoryId != null &&
        selectedCategoryId != 0 &&
        widget.storeId != null &&
        widget.branch != null &&
        mrpController.text.isNotEmpty &&
        selectedUnit != null &&
        skuController.text.isNotEmpty) {
      if (buyPrice >= mrp || sellPrice >= mrp) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Buy & Sell price must be less than MRP")));
        return;
      }
      final productMap = {
        "name": nameController.text,
        "category": selectedCategoryId,
        "online_visibility": onlineVisibility,
        "mrp": mrp,
        "buy_price": [buyPrice],
        "sell_price": [sellPrice],
        "online_sell_price": onlineSellPrice,
        "quantity": [quantity],
        "store_id": widget.storeId,
        "branch": widget.branch,
        "unit": selectedUnit,
        "barcode": int.tryParse(barcodeController.text) ?? 0,
        "description": descriptionController.text,
        "sku": skuController.text,
        "product_image": _uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty ? {"url": _uploadedImageUrl} : null,
      };

      setState(() {
        _localProducts.add(productMap);
        nameController.clear();
        descriptionController.clear();
        mrpController.clear();
        buyPriceController.clear();
        sellPriceController.clear();
        onlineSellPriceController.clear();
        quantityController.clear();
        skuController.clear();
        barcodeController.clear();

        // reset category to first available, prefer freshly fetched list
        if (_categories.isNotEmpty) {
          selectedCategory = _categories[0];
          selectedCategoryId = selectedCategory!.categoryId;
        } else if (widget.categories.isNotEmpty) {
          selectedCategory = widget.categories[0];
          selectedCategoryId = selectedCategory!.categoryId;
        } else {
          selectedCategory = null;
          selectedCategoryId = null;
        }

        onlineVisibility = true;
        _pickedImageMobile = null;
        _pickedImageWeb = null;
        _uploadedImageUrl = null;
        selectedUnit = _units[0];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all fields with valid data")));
    }
  }

  Future<void> _submitAll() async {
    if (_localProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No products to add!")));
      return;
    }

    // Add via bloc
    _productBloc.add(ProductAddRequested(productsJson: _localProducts, apiUrl: widget.apiUrl));

    // Listen for outcome once
    late StreamSubscription sub;
    sub = _productBloc.stream.listen((state) async {
      if (state is ProductAddInProgress) {
        setState(() => _isAddingProduct = true);
      } else if (state is ProductAddSuccess) {
        setState(() => _isAddingProduct = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Products added successfully")));
        if (widget.fetchInventoryCallback != null) {
          await widget.fetchInventoryCallback!();
        }
        Navigator.of(context).pop();
        await sub.cancel();
      } else if (state is ProductAddFailure) {
        setState(() => _isAddingProduct = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Add failed: ${state.message}')));
        await sub.cancel();
      }
    });
  }

  void _editLocalProduct(int index) {
    final p = _localProducts[index];
    nameController.text = p['name'] ?? '';
    descriptionController.text = p['description'] ?? '';
    mrpController.text = p['mrp']?.toString() ?? '';
    buyPriceController.text = p['buy_price'] != null && p['buy_price'].isNotEmpty ? p['buy_price'][0].toString() : '';
    sellPriceController.text = p['sell_price'] != null && p['sell_price'].isNotEmpty ? p['sell_price'][0].toString() : '';
    onlineSellPriceController.text = p['online_sell_price']?.toString() ?? '';
    quantityController.text = p['quantity'] != null && p['quantity'].isNotEmpty ? p['quantity'][0].toString() : '';
    skuController.text = p['sku'] ?? '';
    barcodeController.text = p['barcode']?.toString() ?? '';
    onlineVisibility = p['online_visibility'] ?? true;
    selectedUnit = p['unit'] ?? _units[0];

    // robustly parse the stored category value (could be int, string, etc.)
    final dynamic catVal = p['category'];
    int? parsedCatId;
    if (catVal is int) {
      parsedCatId = catVal;
    } else if (catVal is String) {
      parsedCatId = int.tryParse(catVal);
    } else if (catVal != null) {
      parsedCatId = int.tryParse(catVal.toString());
    }

    if (parsedCatId != null) {
      final found = _categories.where((c) => c.categoryId == parsedCatId);
      if (found.isNotEmpty) {
        selectedCategory = found.first;
        selectedCategoryId = parsedCatId;
      } else {
        // fallback to widget.categories if fetched list doesn't contain it
        final foundFromWidget = widget.categories.where((c) => c.categoryId == parsedCatId);
        if (foundFromWidget.isNotEmpty) {
          selectedCategory = foundFromWidget.first;
          selectedCategoryId = parsedCatId;
        } else if (_categories.isNotEmpty) {
          selectedCategory = _categories[0];
          selectedCategoryId = selectedCategory!.categoryId;
        } else {
          selectedCategory = widget.categories.isNotEmpty ? widget.categories[0] : null;
          selectedCategoryId = selectedCategory?.categoryId;
        }
      }
    } else {
      selectedCategory = _categories.isNotEmpty ? _categories[0] : (widget.categories.isNotEmpty ? widget.categories[0] : null);
      selectedCategoryId = selectedCategory?.categoryId;
    }

    setState(() {
      _localProducts.removeAt(index);
      _uploadedImageUrl = p['product_image']?['url'];
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _localProducts.removeAt(index);
    });
  }


  Widget _imagePreview() {
    if (_isUploadingImage) return const SizedBox(width: 60, height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) {
      return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_uploadedImageUrl!, height: 60, width: 60, fit: BoxFit.cover));
    }
    if (_pickedImageMobile != null) return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_pickedImageMobile!, height: 60, width: 60, fit: BoxFit.cover));
    if (_pickedImageWeb != null) return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_pickedImageWeb!.path, height: 60, width: 60, fit: BoxFit.cover));
    return Container(height: 60, width: 60, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image, color: Colors.grey));
  }

  Widget _buildProductRow(int index, Map<String, dynamic> product) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: product["product_image"]?["url"] != null ? Image.network(product["product_image"]["url"], width: 48, height: 48, fit: BoxFit.cover) : const Icon(Icons.image),
        title: Text(product["name"] ?? ''),
        subtitle: Text('SKU: ${product["sku"] ?? ''} • Qty: ${product["quantity"]?[0] ?? ''}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editLocalProduct(index)),
          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _removeProduct(index)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductBloc>.value(
      value: _productBloc,
      child: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          // show skeleton while adding or uploading for smooth feedback
          if (state is ProductAddInProgress || state is ProductImageUploadInProgress) {
            return const AddProductSkeleton();
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Add New Product')),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(children: [
                      _imagePreview(),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isAddingProduct ? null : _pickImage,
                        icon: const Icon(Icons.upload, color: Colors.white),
                        label: const Text('Pick Image'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name', filled: true, fillColor: Color(0xFFF5F5F5), border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description', filled: true, fillColor: Color(0xFFF5F5F5), border: OutlineInputBorder())),
                    const SizedBox(height: 16),

                    // Category dropdown uses fetched _categories (seeded from widget.categories)
                    _isLoadingCategories
                        ? const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()))
                        : (_categoriesError != null
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: null,
                          items: [],
                          onChanged: (_) {},
                          decoration: const InputDecoration(
                            labelText: "Category",
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Failed to load categories'),
                        ),
                        const SizedBox(height: 8),
                        Text(_categoriesError!, style: const TextStyle(color: Colors.red)),
                        TextButton.icon(onPressed: _fetchCategories, icon: const Icon(Icons.refresh), label: const Text('Retry loading categories'))
                      ],
                    )
                        : DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _dropdownValue,
                      items: _categories.map((cat) => DropdownMenuItem<int>(value: cat.categoryId, child: Text(cat.name))).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedCategoryId = val;
                          if (val == null) {
                            selectedCategory = null;
                          } else {
                            selectedCategory = _categories.firstWhere((c) => c.categoryId == val, orElse: () => _categories.isNotEmpty ? _categories[0] : CategoryModel(id: '', name: '', description: '', categoryId: 0));
                          }
                        });
                      },
                      decoration: const InputDecoration(labelText: "Category", filled: true, fillColor: Color(0xFFF5F5F5), border: OutlineInputBorder()),
                      hint: _categories.isEmpty ? const Text('No categories available') : null,
                    )),

                    const SizedBox(height: 16),
                    Row(children: [Checkbox(value: onlineVisibility, onChanged: (v) => setState(() => onlineVisibility = v ?? true)), const Text('Online Visibility')]),
                    const SizedBox(height: 12),
                    TextField(controller: mrpController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'MRP', filled: true, fillColor: Color(0xFFF5F5F5), border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: buyPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Buy Price', filled: true, fillColor: Color(0xFFF5F5F5), border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: sellPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sell Price', filled: true, fillColor: Color(0xFFF5F5F5), border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: onlineSellPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Online Sell Price', filled: true, fillColor: Color(0xFFF5F5F5), border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: selectedUnit,
                          items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (v) => setState(() => selectedUnit = v),
                          decoration: const InputDecoration(labelText: 'Unit', filled: true, fillColor: Color(0xFFF5F5F5), border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: TextField(controller: quantityController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: selectedUnit == 'Nos' ? 'Quantity (Nos)' : 'Quantity', filled: true, fillColor: const Color(0xFFF5F5F5), border: const OutlineInputBorder()))),
                    ]),
                    const SizedBox(height: 12),
                    TextField(controller: barcodeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Barcode', filled: true, fillColor: Color(0xFFF5F5F5), border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: skuController, decoration: const InputDecoration(labelText: 'SKU', filled: true, fillColor: Color(0xFFF5F5F5), border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: ElevatedButton(onPressed: _addProductToList, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Add Product'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(onPressed: () => Navigator.of(context).pop(), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Cancel'))),
                    ]),
                    const SizedBox(height: 16),
                    if (_localProducts.isNotEmpty) ...[
                      const Text('Products to be Added:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._localProducts.asMap().entries.map((e) => _buildProductRow(e.key, e.value)).toList(),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _isAddingProduct ? null : _submitAll, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), child: const Text('Submit All Products')),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}