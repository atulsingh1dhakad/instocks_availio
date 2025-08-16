import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'addnewproduct.dart';

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
      barrierDismissible: !(isEdit ? _isEditingProduct : false),
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
                setStateDialog(() => _isEditingProduct = true);
                try {
                  final headers = await _getAuthHeaders();
                  final Map<String, dynamic> payload = {
                    "name": nameController.text,
                    "category": _selectedCategory.categoryId,
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
                  if (isEdit && product != null && product["product_id"] != null) {
                    url = Uri.parse('${apiUrl}products/update/${product["product_id"]}');
                    resp = await http.put(
                      url,
                      headers: headers,
                      body: jsonEncode(payload),
                    );
                  } else {
                    throw Exception('Add product not allowed here');
                  }

                  setStateDialog(() {
                    _isEditingProduct = false;
                  });

                  if (resp.statusCode == 200 || resp.statusCode == 201) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Product updated")),
                    );
                    await fetchUserAndInventory();
                  } else {
                    String errorText = "Failed to update product";
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
                    _isEditingProduct = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill in all fields with valid data")),
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
                      Text("Edit Product", style: const TextStyle(color: Colors.black, fontSize: 18)),
                      const SizedBox(height: 16),
                      _buildTextField(nameController, "Product Name"),
                      const SizedBox(height: 16),
                      _buildTextField(descriptionController, "Description"),
                      const SizedBox(height: 16),
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
                      _buildTextField(buyPriceController, "Buy Price", keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTextField(sellPriceController, "Sell Price", keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTextField(quantityController, "Quantity", keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTextField(unitController, "Unit"),
                      const SizedBox(height: 16),
                      _buildTextField(skuController, "SKU"),
                      const SizedBox(height: 16),
                      if (_isEditingProduct)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: CircularProgressIndicator(),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isEditingProduct ? null : () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: _isEditingProduct ? null : handleAction,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                            child: const Text("Update", style: TextStyle(color: Colors.white)),
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

  // Send {"product_id": int} to products/del-prod via POST
  Future<void> _deleteProduct(int productId) async {
    final headers = await _getAuthHeaders();
    try {
      final url = Uri.parse('${apiUrl}products/del-prod');
      final resp = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"product_id": productId}),
      );
      if (resp.statusCode == 200) {
        setState(() {
          inventory.removeWhere((item) => item['product_id'] == productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product deleted from inventory")),
        );
        await fetchUserAndInventory();
      } else {
        String errorText = "Failed to delete product";
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
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
      body: Stack(
        children: [
          isLoading
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
            padding: const EdgeInsets.only(bottom: 80.0), // leave space for buttons
            child: ListView.builder(
              itemCount: inventory.length,
              itemBuilder: (context, index) {
                final product = inventory[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                              child: Image.network(
                                product["image"] ??
                                    "https://www.pngall.com/wp-content/uploads/8/Sample.png",
                                height: 50,
                                width: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    height: 50,
                                    width: 50,
                                    child: const Icon(Icons.image, color: Colors.grey),
                                  );
                                },
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
                                      _metricBox("Cat", _getCategoryName(product["category"])),
                                      _metricBox("Unit", product["unit"]),
                                      _metricBox("SKU", product["sku"]),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _metricBox(
                                          "Buy",
                                          product["buy_price"] is List &&
                                              product["buy_price"].isNotEmpty
                                              ? product["buy_price"][0]
                                              : ""),
                                      const SizedBox(width: 5),
                                      _metricBox(
                                          "Sell",
                                          product["sell_price"] is List &&
                                              product["sell_price"].isNotEmpty
                                              ? product["sell_price"][0]
                                              : ""),
                                      const SizedBox(width: 5),
                                      _metricBox(
                                          "Qty",
                                          product["quantity"] is List &&
                                              product["quantity"].isNotEmpty
                                              ? product["quantity"][0]
                                              : ""),
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
                                  onPressed: () => _showEditProductDialog(context, product),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteProduct(product['product_id'] ?? 0),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Bottom button bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      // "Add New Product" navigates as before
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => AddNewProductScreen(
                            storeId: storeId,
                            branch: branch,
                            categories: categories,
                            apiUrl: apiUrl,
                            apiToken: apiToken,
                            fetchInventoryCallback: fetchUserAndInventory,
                          ),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Add New Product', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      // "Add Product" navigates the same as "Add New Product"
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => AddNewProductScreen(
                            storeId: storeId,
                            branch: branch,
                            categories: categories,
                            apiUrl: apiUrl,
                            apiToken: apiToken,
                            fetchInventoryCallback: fetchUserAndInventory,
                          ),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Add Product', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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