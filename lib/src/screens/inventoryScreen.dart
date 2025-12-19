// lib/src/screens/InventoryScreen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:instockavailio/consts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import 'addnewproduct.dart';
import '../ui/inventory_skeleton.dart';

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
  List<CategoryModel> categories = [];
  CategoryModel? selectedCategory;

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

  Future<Map<String, String>> _getAuthHeaders({bool multipart = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('access_token');
    final String tokenTypeRaw = prefs.getString('token_type') ?? 'Bearer';
    final String tokenType = tokenTypeRaw.trim().isEmpty ? 'Bearer' : tokenTypeRaw.trim();
    final String authorizationHeader =
        '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} ${accessToken ?? ""}';

    return {
      if (!multipart) 'Content-Type': 'application/json',
      'x-api-token': apiToken,
      'Authorization': authorizationHeader,
    };
  }

  // Helper to build URIs safely using API_URL as base.
  // Avoids double slashes and handles query parameters.
  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final String base = API_URL.endsWith('/') ? API_URL : '$API_URL/';
    final String normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final Uri parsed = Uri.parse(base + normalizedPath);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return parsed.replace(queryParameters: queryParameters);
    }
    return parsed;
  }

  Uri _buildFromSegments(List<String> segments, [Map<String, String>? queryParameters]) {
    final String base = API_URL.endsWith('/') ? API_URL : '$API_URL/';
    final cleaned = segments
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => s.startsWith('/') ? s.substring(1) : s)
        .join('/');
    final Uri parsed = Uri.parse(base + cleaned);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return parsed.replace(queryParameters: queryParameters);
    }
    return parsed;
  }

  /// Fetch user info and inventory.
  /// Primary endpoint tried: /store/inventory/{store_id}
  /// Falls back to a few other common variants if the primary returns 404.
  Future<void> fetchUserAndInventory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final headers = await _getAuthHeaders();

      // Fetch current user to get storeId (preferred) and branch (optional)
      final userUrl = _buildUri('users/me');
      debugPrint('GET $userUrl');
      debugPrint('HEADERS: $headers');
      final userResp = await http.get(userUrl, headers: headers);
      debugPrint('users/me -> ${userResp.statusCode}: ${userResp.body}');

      if (userResp.statusCode != 200) {
        String detail = userResp.body;
        try {
          final j = json.decode(userResp.body);
          if (j is Map && (j['detail'] != null || j['message'] != null)) {
            detail = (j['detail'] ?? j['message']).toString();
          }
        } catch (_) {}
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load user data: ${userResp.statusCode} — $detail";
        });
        return;
      }

      final userJson = json.decode(userResp.body) as Map<String, dynamic>;
      storeId = (userJson['store_id'] ?? userJson['store'] ?? userJson['storeId'])?.toString();
      branch = (userJson['branch'] ?? userJson['branch_id'])?.toString();

      if (storeId == null || storeId!.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = "User's store_id is missing or empty.";
        });
        return;
      }

      // Build candidate endpoints with store_id primary (the server uses /store/inventory/{store_id})
      final List<Uri> candidates = [];
      final encodedStore = Uri.encodeComponent(storeId!);

      // Primary: /store/inventory/{store_id}
      candidates.add(_buildFromSegments(['store', 'inventory', encodedStore]));

      // Fallbacks (if backend uses different patterns)
      if (branch != null && branch!.isNotEmpty) {
        final encodedBranch = Uri.encodeComponent(branch!);
        // /store/inventory/{store}/{branch} (older format)
        candidates.add(_buildFromSegments(['store', 'inventory', encodedStore, encodedBranch]));
        // /store/inventory/{branch} (some servers expose branch-only)
        candidates.add(_buildFromSegments(['store', 'inventory', encodedBranch]));
      }

      // Query-style fallbacks
      final baseInventory = _buildUri('store/inventory');
      candidates.add(baseInventory.replace(queryParameters: {'store_id': storeId!}));
      if (branch != null && branch!.isNotEmpty) {
        candidates.add(baseInventory.replace(queryParameters: {'store_id': storeId!, 'branch': branch!}));
        candidates.add(baseInventory.replace(queryParameters: {'branch': branch!}));
      }

      // Log candidates
      debugPrint('Inventory endpoint candidates (${candidates.length}):');
      for (final c in candidates) {
        debugPrint(' - $c');
      }

      List<Map<String, dynamic>> items = [];
      http.Response? lastResp;

      // Try candidates until success (200) or exhaust list
      for (final uri in candidates) {
        debugPrint('Trying inventory endpoint: $uri');
        final resp = await http.get(uri, headers: headers);
        debugPrint('-> ${resp.statusCode}: ${resp.body}');
        lastResp = resp;

        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          if (data is List) {
            items = List<Map<String, dynamic>>.from(data);
          } else if (data is Map) {
            // Common fields that may hold the list
            if (data['inventory'] is List) {
              items = List<Map<String, dynamic>>.from(data['inventory']);
            } else if (data['data'] is List) {
              items = List<Map<String, dynamic>>.from(data['data']);
            } else if (data['items'] is List) {
              items = List<Map<String, dynamic>>.from(data['items']);
            } else if (data['products'] is List) {
              items = List<Map<String, dynamic>>.from(data['products']);
            } else {
              // server returned 200 but not a list; treat as zero items
              items = [];
            }
          }
          // stop trying after first 200 (even if items empty)
          break;
        } else if (resp.statusCode == 404) {
          // try next candidate
          continue;
        } else {
          // other non-200 -> show message and stop
          String detail = resp.body;
          try {
            final j = json.decode(resp.body);
            if (j is Map && (j['detail'] != null || j['message'] != null)) {
              detail = (j['detail'] ?? j['message']).toString();
            }
          } catch (_) {}
          setState(() {
            isLoading = false;
            errorMessage = "Failed to load inventory: ${resp.statusCode} — $detail";
          });
          return;
        }
      }

      // Post-loop: if no items found, report helpful message using lastResp
      if (items.isEmpty) {
        if (lastResp != null) {
          if (lastResp.statusCode == 404) {
            String detail = lastResp.body;
            try {
              final j = json.decode(lastResp.body);
              if (j is Map && (j['detail'] != null || j['message'] != null)) {
                detail = (j['detail'] ?? j['message']).toString();
              }
            } catch (_) {}
            setState(() {
              isLoading = false;
              errorMessage =
              "API error ${lastResp?.statusCode} (detail: $detail)\nTried endpoints:\n${candidates.join('\n')}";
            });
            return;
          } else {
            String detail = lastResp.body;
            try {
              final j = json.decode(lastResp.body);
              if (j is Map && (j['detail'] != null || j['message'] != null)) {
                detail = (j['detail'] ?? j['message']).toString();
              }
            } catch (_) {}
            setState(() {
              isLoading = false;
              errorMessage = "Inventory fetch returned ${lastResp?.statusCode}: $detail";
            });
            return;
          }
        } else {
          setState(() {
            isLoading = false;
            errorMessage = "Failed to fetch inventory: no response from server.";
          });
          return;
        }
      }

      // Success: populate inventory
      setState(() {
        inventory = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Exception: $e";
      });
    }
  }

  Future<void> fetchCategories() async {
    try {
      final headers = await _getAuthHeaders();
      final uri = _buildUri('category');
      debugPrint('GET $uri');
      debugPrint('HEADERS: $headers');
      final response = await http.get(uri, headers: headers);
      debugPrint('category -> ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            categories = data.map<CategoryModel>((e) => CategoryModel.fromJson(e)).toList();
            if (categories.isNotEmpty) selectedCategory = categories[0];
          });
        } else if (data is Map && data['data'] is List) {
          setState(() {
            categories = List<Map<String, dynamic>>.from(data['data']).map((e) => CategoryModel.fromJson(e)).toList();
            if (categories.isNotEmpty) selectedCategory = categories[0];
          });
        } else {
          debugPrint('Category endpoint returned non-list response');
        }
      } else {
        debugPrint('Failed to fetch categories: ${response.statusCode} -> ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception while fetching categories: $e');
    }
  }

  Future<void> _showEditProductDialog(BuildContext context, Map<String, dynamic> product) async {
    _showProductDialog(context, isEdit: true, product: product);
  }

  void _showProductDialog(BuildContext context, {required bool isEdit, Map<String, dynamic>? product}) {
    final TextEditingController nameController = TextEditingController(text: product?["name"] ?? "");
    final TextEditingController descriptionController = TextEditingController(text: product?["description"] ?? "");
    final TextEditingController unitController = TextEditingController(text: product?["unit"] ?? "");
    final TextEditingController skuController = TextEditingController(text: product?["sku"] ?? "");

    bool onlineVisibilityLocal = product?["online_visibility"] ?? true;

    CategoryModel _selectedCategoryLocal;
    if (isEdit && product?["category"] != null) {
      _selectedCategoryLocal = categories.firstWhere(
            (cat) => cat.categoryId == product?["category"],
        orElse: () => CategoryModel(id: "", name: "", description: "", categoryId: 0),
      );
    } else {
      _selectedCategoryLocal = selectedCategory ??
          (categories.isNotEmpty ? categories[0] : CategoryModel(id: "", name: "", description: "", categoryId: 0));
    }

    showDialog(
      context: context,
      barrierDismissible: !(isEdit ? _isEditingProduct : false),
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          Future<void> handleAction() async {
            if (nameController.text.isNotEmpty && _selectedCategoryLocal.categoryId != 0 && storeId != null) {
              setStateDialog(() => _isEditingProduct = true);
              try {
                final headers = await _getAuthHeaders();
                final Map<String, dynamic> payload = {
                  "product_id": product?["product_id"],
                  "name": nameController.text,
                  "category": _selectedCategoryLocal.categoryId,
                  "store_id": storeId,
                  "branch": branch,
                  "online_visibility": onlineVisibilityLocal,
                  "unit": unitController.text,
                  "description": descriptionController.text,
                };

                final url = _buildUri('products/update');
                final resp = await http.put(url, headers: headers, body: jsonEncode(payload));

                setStateDialog(() {
                  _isEditingProduct = false;
                });

                if (resp.statusCode == 200 || resp.statusCode == 201) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product updated")));
                  await fetchUserAndInventory();
                } else {
                  String errorText = "Failed to update product";
                  try {
                    final body = jsonDecode(resp.body);
                    if (body is Map && (body['detail'] != null || body['message'] != null)) {
                      errorText = (body['detail'] ?? body['message']).toString();
                    } else {
                      errorText = resp.body.toString();
                    }
                  } catch (_) {
                    errorText = resp.body.toString();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText)));
                }
              } catch (e) {
                setStateDialog(() => _isEditingProduct = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all required fields")));
            }
          }

          return Dialog(
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text("Edit Product", style: TextStyle(color: Colors.black, fontSize: 18)),
                  const SizedBox(height: 16),
                  _buildTextField(nameController, "Product Name"),
                  const SizedBox(height: 16),
                  _buildTextField(descriptionController, "Description"),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CategoryModel>(
                    value: _selectedCategoryLocal.categoryId == 0 ? null : _selectedCategoryLocal,
                    items: categories.map((cat) => DropdownMenuItem<CategoryModel>(value: cat, child: Text(cat.name))).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        _selectedCategoryLocal = val!;
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
                  _buildTextField(unitController, "Unit"),
                  const SizedBox(height: 16),
                  _buildTextField(skuController, "SKU"),
                  const SizedBox(height: 16),
                  Row(children: [
                    Checkbox(value: onlineVisibilityLocal, onChanged: (val) => setStateDialog(() => onlineVisibilityLocal = val ?? true)),
                    const Text("Online Visibility", style: TextStyle(color: Colors.black)),
                  ]),
                  const SizedBox(height: 16),
                  if (_isEditingProduct) const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: CircularProgressIndicator()),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(onPressed: _isEditingProduct ? null : () => Navigator.of(context).pop(), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                    ElevatedButton(onPressed: _isEditingProduct ? null : handleAction, style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent), child: const Text("Update", style: TextStyle(color: Colors.white))),
                  ])
                ]),
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _deleteProduct(int productId) async {
    final headers = await _getAuthHeaders();
    try {
      final url = _buildUri('products/del-prod');
      final resp = await http.post(url, headers: headers, body: jsonEncode({"product_id": productId}));
      if (resp.statusCode == 200) {
        setState(() {
          inventory.removeWhere((item) => item['product_id'] == productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product deleted from inventory")));
        await fetchUserAndInventory();
      } else {
        String errorText = resp.body;
        try {
          final body = jsonDecode(resp.body);
          if (body is Map && (body['detail'] != null || body['message'] != null)) {
            errorText = (body['detail'] ?? body['message']).toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  String _getCategoryName(int? catId) {
    if (catId == null) return "";
    final found = categories.firstWhere((cat) => cat.categoryId == catId, orElse: () => CategoryModel(id: "", name: "", description: "", categoryId: catId));
    return found.name.isNotEmpty ? found.name : catId.toString();
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.black), filled: true, fillColor: const Color(0xFFF5F5F5), border: const OutlineInputBorder()),
      style: const TextStyle(color: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Use shimmer skeleton while loading
    if (isLoading) {
      return const InventorySkeleton();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Inventory Management", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.black), onPressed: () {
            fetchCategories();
            fetchUserAndInventory();
          })
        ],
      ),
      body: errorMessage != null
          ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
          : inventory.isEmpty
          ? const Center(child: Text('No products found.', style: TextStyle(color: Colors.black)))
          : Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
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
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300, width: 1)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            product["image"] ?? "https://www.pngall.com/wp-content/uploads/8/Sample.png",
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(color: Colors.grey[200], height: 50, width: 50, child: const Icon(Icons.image, color: Colors.grey));
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product["name"] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(product["description"] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Wrap(spacing: 5, runSpacing: 4, children: [
                                _metricBox("Cat", _getCategoryName(product["category"])),
                                _metricBox("Unit", product["unit"]),
                                _metricBox("SKU", product["sku"]),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                _metricBox("Buy", product["buy_price"] is List && product["buy_price"].isNotEmpty ? product["buy_price"][0] : ""),
                                const SizedBox(width: 5),
                                _metricBox("Sell", product["sell_price"] is List && product["sell_price"].isNotEmpty ? product["sell_price"][0] : ""),
                                const SizedBox(width: 5),
                                _metricBox("Qty", product["quantity"] is List && product["quantity"].isNotEmpty ? product["quantity"][0] : ""),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _showEditProductDialog(context, product)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () => _deleteProduct(product['product_id'] ?? 0)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNewProductScreen(storeId: storeId, branch: branch, categories: categories, apiUrl: API_URL, apiToken: apiToken, fetchInventoryCallback: fetchUserAndInventory)));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Add New Product', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddNewProductScreen(storeId: storeId, branch: branch, categories: categories, apiUrl: API_URL, apiToken: apiToken, fetchInventoryCallback: fetchUserAndInventory)));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Add Product', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Colors.grey[100], border: Border.all(color: Colors.grey.shade300)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 10)),
        Text(value == null ? "" : value.toString(), style: const TextStyle(color: Colors.black87, fontSize: 10)),
      ]),
    );
  }
}