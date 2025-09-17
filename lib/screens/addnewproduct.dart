import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../consts.dart';
import 'InventoryScreen.dart';

class AddNewProductScreen extends StatefulWidget {
  final String? storeId;
  final String? branch;
  final List<Category> categories;
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
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController mrpController = TextEditingController();
  final TextEditingController buyPriceController = TextEditingController();
  final TextEditingController sellPriceController = TextEditingController();
  final TextEditingController onlineSellPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();

  Category? selectedCategory;
  bool _isAddingProduct = false;
  bool onlineVisibility = true;

  XFile? _pickedImageWeb;
  File? _pickedImageMobile;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  final List<String> _units = ['KG', 'GM', 'Liter', 'Mililiter', 'Nos'];
  String? selectedUnit;

  List<Map<String, dynamic>> _localProducts = [];

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      selectedCategory = widget.categories[0];
    }
    selectedUnit = _units[0];
  }

  Future<Map<String, String>> _getAuthHeaders({bool multipart = false}) async {
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
      if (!multipart) 'Content-Type': 'application/json',
      X_api_token: widget.apiToken,
      'Authorization': authorizationHeader,
    };
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _isUploadingImage = true;
      });
      if (kIsWeb) {
        setState(() {
          _pickedImageWeb = picked;
          _pickedImageMobile = null;
        });
      } else {
        setState(() {
          _pickedImageMobile = File(picked.path);
          _pickedImageWeb = null;
        });
      }
      // Automatically upload after picking
      await _uploadImageAndSetUrl(picked);
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _uploadImageAndSetUrl(XFile pickedImage) async {
    setState(() {
      _uploadedImageUrl = null;
    });
    final headers = await _getAuthHeaders(multipart: true);

    final uri = Uri.parse('${widget.apiUrl}products/upload-product-image')
        .replace(queryParameters: {
      'store_id': widget.storeId ?? '',
    });

    var request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers);

    if (kIsWeb) {
      var bytes = await pickedImage.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: pickedImage.name,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          pickedImage.path,
        ),
      );
    }

    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      setState(() {
        _uploadedImageUrl = data['url'] ?? '';
      });
    } else {
      setState(() {
        _uploadedImageUrl = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: ${resp.body}")),
      );
    }
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
        selectedCategory != null &&
        selectedCategory!.categoryId != 0 &&
        widget.storeId != null &&
        widget.branch != null &&
        mrpController.text.isNotEmpty &&
        selectedUnit != null &&
        skuController.text.isNotEmpty) {
      if (buyPrice >= mrp || sellPrice >= mrp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Buy & Sell price must be less than MRP")),
        );
        return;
      }
      final Map<String, dynamic> productMap = {
        "name": nameController.text,
        "category": selectedCategory!.categoryId,
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
        "product_image": _uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty
            ? {"url": _uploadedImageUrl}
            : null,
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
        selectedCategory = widget.categories.isNotEmpty ? widget.categories[0] : null;
        onlineVisibility = true;
        _pickedImageMobile = null;
        _pickedImageWeb = null;
        _uploadedImageUrl = null;
        selectedUnit = _units[0];
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
    onlineSellPriceController.text = product["online_sell_price"]?.toString() ?? '';
    quantityController.text = product["quantity"] != null && product["quantity"].isNotEmpty
        ? product["quantity"][0].toString()
        : '';
    skuController.text = product["sku"] ?? '';
    barcodeController.text = product["barcode"]?.toString() ?? '';
    onlineVisibility = product["online_visibility"] ?? true;
    selectedUnit = product["unit"] ?? _units[0];

    selectedCategory = widget.categories.firstWhere(
          (cat) => cat.categoryId == product["category"],
      orElse: () => Category(id: "", name: "", description: "", categoryId: 0),
    );
    setState(() {
      _localProducts.removeAt(index);
      _pickedImageWeb = null;
      _pickedImageMobile = null;
      _uploadedImageUrl = product["product_image"]?["url"];
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _localProducts.removeAt(index);
    });
  }

  Widget _productCard(Map<String, dynamic> product, int index) {
    Widget imageWidget;
    final url = product["product_image"] is Map && product["product_image"]["url"] != null
        ? product["product_image"]["url"].toString()
        : null;

    if (url != null && url.isNotEmpty) {
      imageWidget = Image.network(
        url,
        height: 50,
        width: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.image, color: Colors.grey, size: 40),
      );
    } else {
      imageWidget = Icon(Icons.image, color: Colors.grey, size: 40);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
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
                    child: imageWidget,
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
                          _metricBox("Online Sell Price", product["online_sell_price"]),
                          _metricBox("Online Vis.", product["online_visibility"] == true ? "Yes" : "No"),
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
            style: const TextStyle(color: Colors.black87, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, bool enabled = true}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
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

  Widget _buildImagePreviewAndUrl() {
    if (_isUploadingImage) {
      return Container(
        height: 60,
        width: 60,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty) {
      return Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.image, color: Colors.grey),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image preview
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _uploadedImageUrl!,
            height: 60,
            width: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.image, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        // Blurry URL
        SizedBox(
          width: 220,
          child: Stack(
            children: [
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    color: Colors.grey.withOpacity(0.2),
                    height: 30,
                    child: Text(
                      _uploadedImageUrl!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: "monospace",
                        fontSize: 13,
                        color: Colors.black,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  color: Colors.white.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                  child: const Text(
                    "Image URL",
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
              // Image Picker Row + Preview & Blurry URL
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImagePreviewAndUrl(),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isAddingProduct ? null : _pickImage,
                    icon: Icon(Icons.upload, color: Colors.white),
                    label: Text('Pick Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              Row(
                children: [
                  Checkbox(
                    value: onlineVisibility,
                    onChanged: (val) {
                      setState(() {
                        onlineVisibility = val ?? true;
                      });
                    },
                  ),
                  const Text("Online Visibility",
                      style: TextStyle(color: Colors.black)),
                ],
              ),
              _buildTextField(mrpController, "MRP", keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(
                  buyPriceController, "Buy Price",
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(
                  sellPriceController, "Sell Price",
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(
                  onlineSellPriceController, "Online Sell Price",
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: selectedUnit,
                      items: _units.map((unit) => DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedUnit = val!;
                          quantityController.clear();
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        labelStyle: TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      quantityController,
                      selectedUnit == 'Nos' ? "Quantity (Nos)" : "Quantity",
                      keyboardType: TextInputType.number,
                      enabled: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                  barcodeController, "Barcode",
                  keyboardType: TextInputType.number),
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