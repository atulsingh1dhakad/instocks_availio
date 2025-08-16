import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../consts.dart';
import 'InventoryScreen.dart';

class AddNewProductScreen extends StatefulWidget {
  final String? storeId;
  final String? branch;
  final List<Category> categories;
  final String apiUrl; // Set based on kIsWeb logic
  final String apiToken; // Pass X_api_token from consts.dart
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
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController mrpController = TextEditingController();
  final TextEditingController buyPriceController = TextEditingController();
  final TextEditingController sellPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();

  Category? selectedCategory;
  bool _isAddingProduct = false;

  List<Map<String, dynamic>> _localProducts = [];

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      selectedCategory = widget.categories[0];
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('access_token');
    final String? tokenTypeRaw = prefs.getString('token_type');
    final String tokenType = (tokenTypeRaw ?? 'Bearer').trim();
    final String? useAccessToken =
    accessToken != null && accessToken.trim().isNotEmpty
        ? accessToken.trim()
        : null;
    final String authorizationHeader =
        '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} ${useAccessToken ?? ""}';

    return {
      'Content-Type': 'application/json',
      X_api_token: widget.apiToken, // From consts.dart
      'Authorization': authorizationHeader,
    };
  }

  void _addProductToList() {
    if (nameController.text.isNotEmpty &&
        buyPriceController.text.isNotEmpty &&
        sellPriceController.text.isNotEmpty &&
        quantityController.text.isNotEmpty &&
        selectedCategory != null &&
        selectedCategory!.categoryId != 0 &&
        widget.storeId != null &&
        widget.branch != null &&
        mrpController.text.isNotEmpty) {
      final Map<String, dynamic> productMap = {
        "name": nameController.text,
        "category": selectedCategory!.categoryId,
        "mrp": double.tryParse(mrpController.text) ?? 0.0,
        "buy_price": [double.tryParse(buyPriceController.text) ?? 0.0],
        "sell_price": [double.tryParse(sellPriceController.text) ?? 0.0],
        "quantity": [int.tryParse(quantityController.text) ?? 1],
        "store_id": widget.storeId,
        "branch": widget.branch,
        "unit": unitController.text,
        "barcode": int.tryParse(barcodeController.text) ?? 0,
        "description": descriptionController.text,
        "sku": skuController.text,
      };

      setState(() {
        _localProducts.add(productMap);
        nameController.clear();
        descriptionController.clear();
        mrpController.clear();
        buyPriceController.clear();
        sellPriceController.clear();
        quantityController.clear();
        unitController.clear();
        skuController.clear();
        barcodeController.clear();
        selectedCategory = widget.categories.isNotEmpty ? widget.categories[0] : null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields with valid data")),
      );
    }
  }

  Future<void> _postProducts() async {
    if (_localProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No products to add!")),
      );
      return;
    }
    setState(() => _isAddingProduct = true);
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('${widget.apiUrl}products/add-many');
      final resp = await http.post(
        url,
        headers: headers,
        body: jsonEncode(_localProducts),
      );

      setState(() {
        _isAddingProduct = false;
      });

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Products added successfully")),
        );
        if (widget.fetchInventoryCallback != null) {
          await widget.fetchInventoryCallback!();
        }
        Navigator.of(context).pop();
      } else {
        String errorText = "Failed to add products";
        try {
          final body = jsonDecode(resp.body);
          if (body is Map && body['detail'] != null) {
            errorText = "Error: ${body['detail']}";
          } else if (body is Map && body['message'] != null) {
            errorText = "Error: ${body['message']}";
          } else {
            errorText = resp.body.toString();
          }
        } catch (_) {
          errorText = resp.body.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorText)),
        );
      }
    } catch (e) {
      setState(() => _isAddingProduct = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _editProduct(int index) {
    final product = _localProducts[index];
    nameController.text = product["name"] ?? '';
    descriptionController.text = product["description"] ?? '';
    mrpController.text = product["mrp"]?.toString() ?? '';
    buyPriceController.text = product["buy_price"] != null && product["buy_price"].isNotEmpty
        ? product["buy_price"][0].toString()
        : '';
    sellPriceController.text = product["sell_price"] != null && product["sell_price"].isNotEmpty
        ? product["sell_price"][0].toString()
        : '';
    quantityController.text = product["quantity"] != null && product["quantity"].isNotEmpty
        ? product["quantity"][0].toString()
        : '';
    unitController.text = product["unit"] ?? '';
    skuController.text = product["sku"] ?? '';
    barcodeController.text = product["barcode"]?.toString() ?? '';
    selectedCategory = widget.categories.firstWhere(
          (cat) => cat.categoryId == product["category"],
      orElse: () => Category(id: "", name: "", description: "", categoryId: 0), // Always return Category, not null!
    );
    setState(() {
      _localProducts.removeAt(index);
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _localProducts.removeAt(index);
    });
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: const OutlineInputBorder(),
      ),
      style: const TextStyle(color: Colors.black),
    );
  }

  Widget _productCard(Map<String, dynamic> product, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                spreadRadius: 1,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    color: Colors.grey[200],
                    height: 50,
                    width: 50,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product["name"] ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product["description"] ?? "",
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          _metricBox("Cat", product["category"]),
                          _metricBox("Unit", product["unit"]),
                          _metricBox("SKU", product["sku"]),
                          _metricBox("MRP", product["mrp"]),
                          _metricBox("Barcode", product["barcode"]),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _metricBox("Buy", product["buy_price"] != null && product["buy_price"].isNotEmpty ? product["buy_price"][0] : ""),
                          const SizedBox(width: 5),
                          _metricBox("Sell", product["sell_price"] != null && product["sell_price"].isNotEmpty ? product["sell_price"][0] : ""),
                          const SizedBox(width: 5),
                          _metricBox("Qty", product["quantity"] != null && product["quantity"].isNotEmpty ? product["quantity"][0] : ""),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () => _editProduct(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      onPressed: () => _removeProduct(index),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricBox(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 10),
          ),
          Text(
            value == null ? "" : value.toString(),
            style:
            const TextStyle(color: Colors.black87, fontSize: 10),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(nameController, "Product Name"),
              const SizedBox(height: 16),
              _buildTextField(descriptionController, "Description"),
              const SizedBox(height: 16),
              DropdownButtonFormField<Category>(
                value: selectedCategory,
                items: widget.categories.map((cat) => DropdownMenuItem<Category>(
                  value: cat,
                  child: Text(cat.name),
                )).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedCategory = val!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Category",
                  labelStyle: TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Color(0xFFF5F5F5),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(mrpController, "MRP", keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(buyPriceController, "Buy Price", keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(sellPriceController, "Sell Price", keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(quantityController, "Quantity", keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(unitController, "Unit"),
              const SizedBox(height: 16),
              _buildTextField(barcodeController, "Barcode", keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(skuController, "SKU"),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isAddingProduct ? null : _addProductToList,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Add Product', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isAddingProduct
                          ? null
                          : () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isAddingProduct)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: CircularProgressIndicator(),
                ),
              // Product List
              if (_localProducts.isNotEmpty)
                Column(
                  children: [
                    const Text('Products to be Added:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._localProducts
                        .asMap()
                        .entries
                        .map((entry) =>
                        _productCard(entry.value, entry.key))
                        .toList(),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isAddingProduct ? null : _postProducts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Submit All Products', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}