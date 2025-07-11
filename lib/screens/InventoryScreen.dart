import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Category model
class Category {
  final String id;
  final String name;
  final String description;
  final int categoryId;
  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
  });
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['_id'] ?? "",
    name: json['category_name'] ?? "",
    description: json['category_description'] ?? "",
    categoryId: json['category_id'] ?? 0,
  );
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> inventory = [];
  bool isLoading = true;
  String? errorMessage;
  String? storeId;
  String? branch;
  bool _isAddingProduct = false;
  bool _isEditingProduct = false;
  List<Category> categories = [];
  Category? selectedCategory;

  static const String WEB_API_URL =
      "https://cors-anywhere.herokuapp.com/https://avalio-api.onrender.com/";
  static const String APP_API_URL = "https://avalio-api.onrender.com/";
  String get apiUrl => kIsWeb ? WEB_API_URL : APP_API_URL;
  static const String apiToken = '0ff738d516ce887efe7274d43acd8043';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchCategories();
    fetchUserAndInventory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchUserAndInventory();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchUserAndInventory();
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
      'x-api-token': apiToken,
      'Authorization': authorizationHeader,
    };
  }

  Future<void> fetchUserAndInventory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final headers = await _getAuthHeaders();

      final userUrl = Uri.parse('${apiUrl}users/me');
      final userResp = await http.get(
        userUrl,
        headers: headers,
      );

      if (userResp.statusCode != 200) {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load user data: ${userResp.statusCode}";
        });
        return;
      }

      final userJson = json.decode(userResp.body);
      storeId = userJson['store_id'];
      branch = userJson['branch'];

      if (storeId == null || branch == null) {
        setState(() {
          isLoading = false;
          errorMessage = "User's store_id or branch is missing.";
        });
        return;
      }

      final invUrl = Uri.parse('${apiUrl}store/inventory/$storeId/$branch');
      final invResp = await http.get(
        invUrl,
        headers: headers,
      );

      if (invResp.statusCode != 200) {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load inventory: ${invResp.statusCode}";
        });
        return;
      }

      final data = json.decode(invResp.body);
      List<Map<String, dynamic>> items = [];
      if (data is List) {
        items = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data["inventory"] is List) {
        items = List<Map<String, dynamic>>.from(data["inventory"]);
      }

      setState(() {
        inventory = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error: $e";
      });
    }
  }

  Future<void> fetchCategories() async {
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('${apiUrl}category');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            categories = data.map<Category>((e) => Category.fromJson(e)).toList();
            if (categories.isNotEmpty) selectedCategory = categories[0];
          });
        }
      }
    } catch (e) {
      // Optionally handle error
    }
  }

  void _showAddProductDialog(BuildContext context) {
    _showProductDialog(context, isEdit: false);
  }

  void _showEditProductDialog(BuildContext context, Map<String, dynamic> product) {
    _showProductDialog(context, isEdit: true, product: product);
  }

  void _showProductDialog(BuildContext context,
      {required bool isEdit, Map<String, dynamic>? product}) {
    final TextEditingController nameController =
    TextEditingController(text: product?["name"] ?? "");
    final TextEditingController descriptionController =
    TextEditingController(text: product?["description"] ?? "");
    final TextEditingController buyPriceController = TextEditingController(
        text: (product?["buy_price"] is List && product!["buy_price"].isNotEmpty)
            ? product["buy_price"][0].toString()
            : "");
    final TextEditingController sellPriceController = TextEditingController(
        text: (product?["sell_price"] is List && product!["sell_price"].isNotEmpty)
            ? product["sell_price"][0].toString()
            : "");
    final TextEditingController quantityController = TextEditingController(
        text: (product?["quantity"] is List && product!["quantity"].isNotEmpty)
            ? product["quantity"][0].toString()
            : "");
    final TextEditingController unitController =
    TextEditingController(text: product?["unit"] ?? "");
    final TextEditingController skuController =
    TextEditingController(text: product?["sku"] ?? "");

    Category _selectedCategory;
    if (isEdit && product?["category"] != null) {
      _selectedCategory = categories.firstWhere(
            (cat) => cat.categoryId == product?["category"],
        orElse: () => Category(id: "", name: "", description: "", categoryId: 0),
      );
    } else {
      _selectedCategory = selectedCategory ?? (categories.isNotEmpty ? categories[0] : Category(id: "", name: "", description: "", categoryId: 0));
    }

    showDialog(
      context: context,
      barrierDismissible: !(isEdit ? _isEditingProduct : _isAddingProduct),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> handleAction() async {
              if (nameController.text.isNotEmpty &&
                  buyPriceController.text.isNotEmpty &&
                  sellPriceController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty &&
                  _selectedCategory.categoryId != 0 &&
                  storeId != null &&
                  branch != null) {
                if (isEdit) {
                  setStateDialog(() => _isEditingProduct = true);
                } else {
                  setStateDialog(() => _isAddingProduct = true);
                }
                try {
                  final headers = await _getAuthHeaders();
                  final Map<String, dynamic> payload = {
                    "name": nameController.text,
                    "category": _selectedCategory.categoryId, // Use category_id (serial number)
                    "buy_price": [
                      double.tryParse(buyPriceController.text) ?? 0.0
                    ],
                    "sell_price": [
                      double.tryParse(sellPriceController.text) ?? 0.0
                    ],
                    "store_id": storeId,
                    "branch": branch,
                    "quantity": [
                      int.tryParse(quantityController.text) ?? 1
                    ],
                    "unit": unitController.text,
                    "description": descriptionController.text,
                    "sku": skuController.text,
                  };

                  Uri url;
                  http.Response resp;
                  if (isEdit && product != null && product["id"] != null) {
                    url = Uri.parse('${apiUrl}products/update/${product["id"]}');
                    resp = await http.put(
                      url,
                      headers: headers,
                      body: jsonEncode(payload),
                    );
                  } else {
                    url = Uri.parse('${apiUrl}products/add');
                    resp = await http.post(
                      url,
                      headers: headers,
                      body: jsonEncode(payload),
                    );
                  }

                  setStateDialog(() {
                    if (isEdit) {
                      _isEditingProduct = false;
                    } else {
                      _isAddingProduct = false;
                    }
                  });

                  if (resp.statusCode == 200 || resp.statusCode == 201) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              isEdit ? "Product updated" : "Product added")),
                    );
                    await fetchUserAndInventory();
                  } else {
                    String errorText = isEdit
                        ? "Failed to update product"
                        : "Failed to add product";
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
                  setStateDialog(() {
                    if (isEdit) {
                      _isEditingProduct = false;
                    } else {
                      _isAddingProduct = false;
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Please fill in all fields with valid data")),
                );
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isEdit ? "Edit Product" : "Add Product",
                          style: const TextStyle(
                              color: Colors.black, fontSize: 18)),
                      const SizedBox(height: 16),
                      _buildTextField(nameController, "Product Name"),
                      const SizedBox(height: 16),
                      _buildTextField(descriptionController, "Description"),
                      const SizedBox(height: 16),
                      // Category Dropdown
                      DropdownButtonFormField<Category>(
                        value: _selectedCategory.categoryId == 0 ? null : _selectedCategory,
                        items: categories.map((cat) => DropdownMenuItem<Category>(
                          value: cat,
                          child: Text(cat.name),
                        )).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            _selectedCategory = val!;
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
                      _buildTextField(buyPriceController, "Buy Price",
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTextField(sellPriceController, "Sell Price",
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTextField(quantityController, "Quantity",
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTextField(unitController, "Unit"),
                      const SizedBox(height: 16),
                      _buildTextField(skuController, "SKU"),
                      const SizedBox(height: 16),
                      if (isEdit ? _isEditingProduct : _isAddingProduct)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: CircularProgressIndicator(),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: (isEdit
                                ? _isEditingProduct
                                : _isAddingProduct)
                                ? null
                                : () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel",
                                style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: (isEdit
                                ? _isEditingProduct
                                : _isAddingProduct)
                                ? null
                                : handleAction,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent),
                            child: Text(isEdit ? "Update" : "Add",
                                style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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

  void _deleteProduct(String productId) {
    setState(() {
      inventory.removeWhere((item) => item['id'] == productId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Product deleted from inventory")),
    );
    // Optionally, reload inventory from server after deletion (if deletion is implemented in API)
    // fetchUserAndInventory();
  }

  String _getCategoryName(int? catId) {
    if (catId == null) return "";
    final found = categories.firstWhere(
            (cat) => cat.categoryId == catId,
        orElse: () => Category(id: "", name: "", description: "", categoryId: catId));
    return found.name.isNotEmpty ? found.name : catId.toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for AutomaticKeepAliveClientMixin
    final double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 4;
    if (screenWidth > 1400) {
      crossAxisCount = 7;
    } else if (screenWidth > 1200) {
      crossAxisCount = 6;
    } else if (screenWidth > 900) {
      crossAxisCount = 5;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Inventory Management",
            style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              fetchCategories();
              fetchUserAndInventory();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
          child: Text(errorMessage!,
              style: const TextStyle(color: Colors.red)))
          : inventory.isEmpty
          ? const Center(
          child: Text('No products found.',
              style: TextStyle(color: Colors.black)))
          : Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: inventory.length,
          itemBuilder: (context, index) {
            final product = inventory[index];
            return Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              shadowColor: Colors.black26,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.grey.shade300, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(6),
                            child: Image.network(
                              product["image"] ??
                                  "https://www.pngall.com/wp-content/uploads/8/Sample.png",
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error,
                                  stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  height: 40,
                                  width: 40,
                                  child: const Icon(Icons.image,
                                      color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blue, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                _showEditProductDialog(
                                    context, product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent,
                                size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _deleteProduct(
                                product['id'] ?? ""),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        product["name"] ?? "",
                        style: const TextStyle(
                          fontSize: 15,
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
                            color: Colors.grey, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          _metricBox("Cat", _getCategoryName(product["category"])),
                          _metricBox("Unit", product["unit"]),
                          _metricBox("SKU", product["sku"]),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _metricBox(
                              "Buy",
                              product["buy_price"] is List &&
                                  product["buy_price"]
                                      .isNotEmpty
                                  ? product["buy_price"][0]
                                  : ""),
                          const SizedBox(width: 5),
                          _metricBox(
                              "Sell",
                              product["sell_price"] is List &&
                                  product["sell_price"]
                                      .isNotEmpty
                                  ? product["sell_price"][0]
                                  : ""),
                          const SizedBox(width: 5),
                          _metricBox(
                              "Qty",
                              product["quantity"] is List &&
                                  product["quantity"]
                                      .isNotEmpty
                                  ? product["quantity"][0]
                                  : ""),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add, color: Colors.white),
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
}