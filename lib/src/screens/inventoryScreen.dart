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

  // Helper to build URIs safely using API_URL as base.
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
  Future<void> fetchUserAndInventory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {

      final userUrl = _buildUri('users/me');
      debugPrint('GET $userUrl');
      final userResp = await http.get(userUrl, headers: headers);

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

      final List<Uri> candidates = [];
      final encodedStore = Uri.encodeComponent(storeId!);
      candidates.add(_buildFromSegments(['store', 'inventory', encodedStore]));

      if (branch != null && branch!.isNotEmpty) {
        final encodedBranch = Uri.encodeComponent(branch!);
        candidates.add(_buildFromSegments(['store', 'inventory', encodedStore, encodedBranch]));
      }

      List<Map<String, dynamic>> items = [];
      http.Response? lastResp;

      for (final uri in candidates) {
        debugPrint('Trying inventory endpoint: $uri');
        final resp = await http.get(uri, headers: headers);
        lastResp = resp;

        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          if (data is List) {
            items = List<Map<String, dynamic>>.from(data);
          } else if (data is Map) {
            if (data['inventory'] is List) {
              items = List<Map<String, dynamic>>.from(data['inventory']);
            } else if (data['data'] is List) {
              items = List<Map<String, dynamic>>.from(data['data']);
            } else if (data['products'] is List) {
              items = List<Map<String, dynamic>>.from(data['products']);
            }
          }
          break;
        }
      }

        setState(() {
          isLoading = false;
        });
        return;
      }
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
      final uri = _buildUri('category');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            categories = data.map<CategoryModel>((e) => CategoryModel.fromJson(e)).toList();
            if (categories.isNotEmpty) selectedCategory = categories[0];
          });
        }
      }
    } catch (e) {
      debugPrint('Exception while fetching categories: $e');
    }
  }

  Future<void> _deleteProduct(int productId) async {
    try {
      final url = _buildUri('products/del-prod');
      final resp = await http.post(url, headers: headers, body: jsonEncode({"product_id": productId}));
      if (resp.statusCode == 200) {
        await fetchUserAndInventory();
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Add New Product', style: TextStyle(fontSize: 16, color: Colors.white)),
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