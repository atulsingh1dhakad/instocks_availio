import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Configurable API variables
const String apiUrlWeb = "https://cors-anywhere.herokuapp.com/https://avalio-api.onrender.com/";
const String apiUrlApp = "https://avalio-api.onrender.com/";
const String xApiTokenHeader = "x-api-token";
const String apiToken = '0ff738d516ce887efe7274d43acd8043';

class recyclebin extends StatefulWidget {
  const recyclebin({Key? key}) : super(key: key);

  @override
  State<recyclebin> createState() => _recyclebinState();
}

class _recyclebinState extends State<recyclebin> {
  List<Map<String, dynamic>> binProducts = [];
  bool isLoading = true;
  String? errorMessage;

  String get apiUrl => kIsWeb ? apiUrlWeb : apiUrlApp;

  @override
  void initState() {
    super.initState();
    fetchRecycleBin();
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
      xApiTokenHeader: apiToken,
      'Authorization': authorizationHeader,
    };
  }

  Future<void> fetchRecycleBin() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('${apiUrl}products/recycle-bin');
      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        List<Map<String, dynamic>> items = [];
        if (data is List) {
          items = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data["products"] is List) {
          items = List<Map<String, dynamic>>.from(data["products"]);
        }
        setState(() {
          binProducts = items;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load recycle bin: ${resp.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  Future<void> restoreProduct(int productId) async {
    final headers = await _getAuthHeaders();
    try {
      final url = Uri.parse('${apiUrl}products/undel-prod');
      final resp = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"product_id": productId}),
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product restored successfully.")),
        );
        // Refresh bin after restoration
        await fetchRecycleBin();
      } else {
        String errorText = "Failed to restore product";
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

  Future<void> deleteProduct(int productId) async {
    final headers = await _getAuthHeaders();
    try {
      final url = Uri.parse('${apiUrl}products/per-del-prod');
      final resp = await http.delete(
        url,
        headers: headers,
        body: jsonEncode({"product_id": productId}),
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product permanently deleted.")),
        );
        await fetchRecycleBin();
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

  Future<void> deleteAllProducts() async {
    final headers = await _getAuthHeaders();
    try {
      final url = Uri.parse('${apiUrl}products/per-del-all-prod');
      final resp = await http.delete(
        url,
        headers: headers,
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All products permanently deleted.")),
        );
        await fetchRecycleBin();
      } else {
        String errorText = "Failed to delete all products";
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Recycle Bin", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: fetchRecycleBin,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: "Delete All Products",
            onPressed: () async {
              // Confirm before deleting all products
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete All Products"),
                  content: const Text(
                      "Are you sure you want to permanently delete all products in the recycle bin? This action cannot be undone."),
                  actions: [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Delete All"),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              );
              if (shouldDelete == true) {
                await deleteAllProducts();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
          child: Text(errorMessage!,
              style: const TextStyle(color: Colors.red)))
          : binProducts.isEmpty
          ? const Center(
          child: Text('No products in recycle bin.',
              style: TextStyle(color: Colors.black)))
          : ListView.builder(
        itemCount: binProducts.length,
        itemBuilder: (context, index) {
          final product = binProducts[index];
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
                                _metricBox("Unit", product["unit"]),
                                _metricBox("SKU", product["sku"]),
                                _metricBox("Cat", product["category"]),
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
                            icon: const Icon(Icons.restore, color: Colors.green),
                            tooltip: "Restore Product",
                            onPressed: () {
                              restoreProduct(product['product_id'] ?? 0);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: "Delete Product",
                            onPressed: () async {
                              // Confirm before deleting product
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Delete Product"),
                                  content: const Text(
                                      "Are you sure you want to permanently delete this product? This action cannot be undone."),
                                  actions: [
                                    TextButton(
                                      child: const Text("Cancel"),
                                      onPressed: () => Navigator.of(context).pop(false),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text("Delete"),
                                      onPressed: () => Navigator.of(context).pop(true),
                                    ),
                                  ],
                                ),
                              );
                              if (shouldDelete == true) {
                                await deleteProduct(product['product_id'] ?? 0);
                              }
                            },
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
    );
  }
}