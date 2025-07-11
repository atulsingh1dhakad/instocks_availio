import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Billingscreen extends StatefulWidget {
  const Billingscreen({Key? key}) : super(key: key);

  @override
  State<Billingscreen> createState() => _BillingscreenState();
}

class _BillingscreenState extends State<Billingscreen> {
  String searchQuery = "";
  List<Map<String, dynamic>> cart = [];
  double total = 0.0;
  double overallDiscount = 0.0;

  List<Map<String, dynamic>> inventory = [];
  bool isLoading = true;
  String? errorMessage;

  static const String apiToken = '0ff738d516ce887efe7274d43acd8043';
  static const String WEB_API_URL = "https://cors-anywhere.herokuapp.com/https://avalio-api.onrender.com/";
  static const String APP_API_URL = "https://avalio-api.onrender.com/";
  String get apiUrl => kIsWeb ? WEB_API_URL : APP_API_URL;

  @override
  void initState() {
    super.initState();
    fetchUserAndInventory();
  }

  Future<void> fetchUserAndInventory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? accessToken = prefs.getString('access_token');
      final String? tokenTypeRaw = prefs.getString('token_type');
      final String tokenType = (tokenTypeRaw ?? 'Bearer').trim();
      final String? useAccessToken =
      accessToken != null && accessToken.trim().isNotEmpty ? accessToken.trim() : null;
      final String authorizationHeader =
          '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} ${useAccessToken ?? ""}';

      final userUrl = Uri.parse('${apiUrl}users/me');
      final userResp = await http.get(
        userUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-api-token': apiToken,
          'Authorization': authorizationHeader,
        },
      );

      if (userResp.statusCode != 200) {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load user data: ${userResp.statusCode}";
        });
        return;
      }

      final userJson = json.decode(userResp.body);
      final String? storeId = userJson['store_id'];
      final String? branch = userJson['branch'];

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
        headers: {
          'Content-Type': 'application/json',
          'x-api-token': apiToken,
          'Authorization': authorizationHeader,
        },
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

  List<Map<String, dynamic>> get filteredInventory {
    return inventory
        .where((product) => (product['name'] ?? '').toLowerCase().contains(searchQuery))
        .toList();
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final existingItem = cart.firstWhere(
            (item) => item['id'] == product['id'],
        orElse: () => {},
      );
      if (existingItem.isNotEmpty) {
        existingItem['quantity'] += 1;
      } else {
        cart.add({
          ...product,
          'quantity': 1,
          'discount': 0.0,
          'name': product['name'] ?? '',
          'price': _parseDouble(product['price']),
          'description': product['description'] ?? '',
        });
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    total = cart.fold(
      0.0,
          (sum, item) {
        final priceAfterDiscount = (_parseDouble(item['price'])) * (1 - ((item['discount'] ?? 0.0) / 100));
        return sum + (priceAfterDiscount * (item['quantity'] ?? 1));
      },
    );
    total = total * (1 - (overallDiscount / 100));
  }

  Future<void> _generateBill() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('POS System Bill', style: pw.TextStyle(fontSize: 24)),
            pw.Divider(),
            ...cart.map((item) => pw.Text(
              "${item['name']} x${item['quantity']} - ₹${_parseDouble(item['price']).toStringAsFixed(2)} (${item['discount']}% discount)",
            )),
            pw.Divider(),
            pw.Text(
              "Overall Discount: ${overallDiscount.toStringAsFixed(2)}%",
            ),
            pw.Text("Total: ₹${total.toStringAsFixed(2)}"),
          ],
        ),
      ),
    );

    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File("${output.path}/bill.pdf");
      await file.writeAsBytes(await pdf.save());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bill saved to ${file.path}")),
      );
      setState(() {
        cart.clear();
        total = 0.0;
        overallDiscount = 0.0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _showDiscountDialog(Map<String, dynamic> product) {
    final TextEditingController discountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Discount to ${product['name']}"),
          content: TextField(
            controller: discountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: "Enter discount in %"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final discount = double.tryParse(discountController.text) ?? 0.0;
                  product['discount'] = discount;
                  _calculateTotal();
                });
                Navigator.of(context).pop();
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  void _removeFromCart(Map<String, dynamic> item) {
    setState(() {
      cart.removeWhere((cartItem) => cartItem['id'] == item['id']);
      _calculateTotal();
    });
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red))),
      );
    }
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
      appBar: AppBar(
        title: const Text('POS System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchUserAndInventory,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Product Catalog',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: filteredInventory.length,
                            itemBuilder: (context, index) {
                              final product = filteredInventory[index];
                              return GestureDetector(
                                onTap: () => _addToCart(product),
                                child: ProductCard(
                                  productName: product["name"] ?? "",
                                  price: _parseDouble(product["price"]),
                                  image: product["image"] ?? "",
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cart',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: cart.length,
                            itemBuilder: (context, index) {
                              final item = cart[index];
                              return ListTile(
                                title: Text(item['name'] ?? ""),
                                subtitle: Row(
                                  children: [
                                    Text("Discount: ${item['discount'] ?? 0}%"),
                                    const SizedBox(width: 16),
                                    DropdownButton<int>(
                                      value: item['quantity'],
                                      items: List.generate(
                                        10,
                                            (index) => DropdownMenuItem(
                                          value: index + 1,
                                          child: Text("${index + 1}"),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            item['quantity'] = value;
                                            _calculateTotal();
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.percent),
                                      onPressed: () => _showDiscountDialog(item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _removeFromCart(item),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: ₹${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _generateBill,
                              child: const Text('Checkout'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text(
                              'Apply Discount (%)',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    overallDiscount = double.tryParse(value) ?? 0.0;
                                    _calculateTotal();
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String productName;
  final double price;
  final String image;

  const ProductCard({
    required this.productName,
    required this.price,
    required this.image,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                image.isNotEmpty
                    ? Image.network(
                  image,
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset('assets/images/thumbnail.png', height: 50, width: 50);
                  },
                )
                    : Image.asset('assets/images/thumbnail.png', height: 50, width: 50),
                const SizedBox(height: 8),
                Text(
                  productName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}