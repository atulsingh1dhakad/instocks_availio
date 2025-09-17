import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:instockavailio/consts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Billingscreen extends StatefulWidget {
  const Billingscreen({Key? key}) : super(key: key);

  @override
  State<Billingscreen> createState() => _BillingscreenState();
}

class _BillingscreenState extends State<Billingscreen> {
  String searchQuery = "";
  List<Map<String, dynamic>> cart = [];
  double total = 0.0;
  double tax = 0.0;
  double subtotal = 0.0;

  List<Map<String, dynamic>> inventory = [];
  String? errorMessage;

  static const String apiToken = '0ff738d516ce887efe7274d43acd8043';

  String customerName = "";
  String customerPhone = "";
  bool customerNameSet = false;

  String paymentMode = "";
  bool isSavingInvoice = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCustomerNameDialog();
    });
    fetchUserAndInventory();
  }

  Future<void> fetchUserAndInventory() async {
    setState(() {
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? accessToken = prefs.getString('access_token');
      final String? tokenTypeRaw = prefs.getString('token_type');
      final String tokenType = (tokenTypeRaw ?? 'Bearer').trim();
      final String? useAccessToken = accessToken != null && accessToken.trim().isNotEmpty ? accessToken.trim() : null;
      final String authorizationHeader = '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} ${useAccessToken ?? ""}';

      // Fetch user info to get store_id and branch
      final userUrl = Uri.parse('${API_URL}users/me');
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
          errorMessage = "Failed to load user data: ${userResp.statusCode}";
        });
        return;
      }

      final userJson = json.decode(userResp.body);
      final String? storeId = userJson['store_id'];
      final String? branch = userJson['branch'];

      if (storeId == null || branch == null) {
        setState(() {
          errorMessage = "User's store_id or branch is missing.";
        });
        return;
      }

      final productsUrl = Uri.parse(
        '${API_URL}products/get-all-product-with-price/?store_id=$storeId&branch=$branch',
      );
      final productsResp = await http.get(
        productsUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-api-token': apiToken,
          'Authorization': authorizationHeader,
        },
      );

      if (productsResp.statusCode != 200) {
        setState(() {
          errorMessage = "Failed to load products: ${productsResp.statusCode}";
        });
        return;
      }

      final productsData = json.decode(productsResp.body);
      List<Map<String, dynamic>> items = [];
      if (productsData is Map && productsData["products"] is List) {
        items = List<Map<String, dynamic>>.from(productsData["products"].map((product) {
          return {
            "id": product["product_id"],
            "name": product["name"],
            "price": product["sell_price"] is List && product["sell_price"].isNotEmpty
                ? product["sell_price"][0]
                : (product["mrp"] ?? 0.0),
            "quantity": product["quantity"] is List && product["quantity"].isNotEmpty
                ? product["quantity"][0]
                : 0.0,
            "barcode": product["barcode"] ?? "",
            "mrp": product["mrp"] ?? "",
            "image": product["image"] ?? null,
            "category": product["category"] ?? "Uncategorized",
          };
        }));
      }

      setState(() {
        inventory = items;
      });
    } catch (e) {
      setState(() {
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
      final existingIndex = cart.indexWhere((item) => item['id'] == product['id']);
      if (existingIndex >= 0) {
        cart[existingIndex]['qty'] += 1;
      } else {
        cart.add({
          ...product,
          'qty': 1,
        });
      }
      _calculateTotal();
    });
  }

  void _increaseQty(int index) {
    setState(() {
      cart[index]['qty'] += 1;
      _calculateTotal();
    });
  }

  void _decreaseQty(int index) {
    setState(() {
      if (cart[index]['qty'] > 1) {
        cart[index]['qty'] -= 1;
      } else {
        cart.removeAt(index);
      }
      _calculateTotal();
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      cart.removeAt(index);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    subtotal = cart.fold(
      0.0,
          (sum, item) => sum + (_parseDouble(item['price']) * (item['qty'] ?? 1)),
    );
    tax = subtotal * 0.044; // 4.4% tax as example
    total = subtotal + tax;
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Show customer name and phone dialog at start or if customer name is empty
  void _showCustomerNameDialog({String error = ""}) {
    String tempCustomerName = "";
    String tempCustomerPhone = "";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Customer Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Customer Name",
                ),
                onChanged: (val) {
                  tempCustomerName = val;
                },
                onSubmitted: (_) {},
              ),
              const SizedBox(height: 10),
              TextField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Phone Number (optional)",
                ),
                onChanged: (val) {
                  tempCustomerPhone = val;
                },
                onSubmitted: (_) {},
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(error, style: const TextStyle(color: Colors.red)),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (tempCustomerName.trim().isNotEmpty) {
                  Navigator.of(context, rootNavigator: true).pop();
                  setState(() {
                    customerName = tempCustomerName.trim();
                    customerPhone = tempCustomerPhone.trim();
                    customerNameSet = true;
                  });
                }
              },
              child: const Text("Save"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  // Payment mode selector
  Widget _paymentModeButtons() {
    final modes = ["cash", "UPI", "card"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: modes.map((mode) {
        final selected = paymentMode == mode;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selected ? Colors.blue : Colors.grey[300],
                foregroundColor: selected ? Colors.white : Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                setState(() {
                  paymentMode = mode;
                });
              },
              child: Text(mode.toUpperCase()),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Cart Preview Panel (now on the right)
  Widget _cartPreview() {
    return Container(
      width: 340,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            color: Colors.green[500],
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: cart.isNotEmpty ? () => setState(() => cart.clear()) : null,
                  icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                  label: const Text('Delete', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0)),
                ),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 20,),
          Text(
            customerName.isEmpty
                ? 'Billing for: ______'
                : 'Billing for: $customerName',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize:20,
            ),
          ),
          if (customerPhone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                'Phone: $customerPhone',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, idx) {
                final item = cart[idx];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: ListTile(
                    dense: true,
                    minVerticalPadding: 0,
                    leading: CircleAvatar(radius: 14, child: Text('${item['qty']}')),
                    title: Text(item['name'], style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    subtitle: Text('ID: ${item['id']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_parseDouble(item['price']).toStringAsFixed(2)}', style: TextStyle(fontSize: 14)),
                        IconButton(
                          icon: Icon(Icons.remove, size: 18),
                          onPressed: () => _decreaseQty(idx),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, size: 18),
                          onPressed: () => _increaseQty(idx),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: [
                _billRow("Subtotal", subtotal.toStringAsFixed(2)),
                _billRow("Tax", tax.toStringAsFixed(2)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(total.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 8),
                _paymentModeButtons(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cart.isNotEmpty && paymentMode.isNotEmpty && !isSavingInvoice
                        ? _handleProceedButton
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isSavingInvoice
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      paymentMode.isEmpty
                          ? "Select Payment Mode"
                          : "Proceed",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                if (cart.isNotEmpty && paymentMode.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Please select a payment mode.",
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleProceedButton() {
    if (customerName.trim().isEmpty) {
      _showCustomerNameDialog(error: "Customer name is required.");
      return;
    }
    _proceedInvoice();
  }

  Future<void> _proceedInvoice() async {
    setState(() => isSavingInvoice = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? accessToken = prefs.getString('access_token');
      final String? tokenTypeRaw = prefs.getString('token_type');
      final String tokenType = (tokenTypeRaw ?? 'Bearer').trim();
      final String? useAccessToken = accessToken != null && accessToken.trim().isNotEmpty ? accessToken.trim() : null;
      final String authorizationHeader = '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} ${useAccessToken ?? ""}';

      final String date = DateTime.now().toIso8601String();
      final String notes = ""; // Add notes from UI if needed
      final String counterId = "C1"; // Replace with actual counter id from user/session

      final items = cart.map((item) => {
        "product_id": item['id'],
        "qty_used": item['qty'],
        "price_used": _parseDouble(item['price']),
      }).toList();

      // If phone is empty, send 0 (int), else parse to int (fallback to 0 if not valid)
      dynamic phoneToSend;
      if (customerPhone.trim().isEmpty) {
        phoneToSend = 0;
      } else {
        phoneToSend = int.tryParse(customerPhone.trim()) ?? 0;
      }

      final invoiceBody = {
        "date": date,
        "customer_name": customerName,
        "phone": phoneToSend,
        "items": items,
        "total": total,
        "payment_mode": paymentMode,
        "notes": notes,
        "counter_id": counterId,
      };

      final url = Uri.parse('${API_URL}invoices/generate-invoice/');
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-api-token': apiToken,
          'Authorization': authorizationHeader,
        },
        body: jsonEncode(invoiceBody),
      );

      setState(() => isSavingInvoice = false);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Invoice Generated'),
            content: const Text('Invoice was generated successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  setState(() {
                    cart.clear();
                    _calculateTotal();
                    errorMessage = null;
                    customerName = "";
                    customerPhone = "";
                    customerNameSet = false;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showCustomerNameDialog();
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to generate invoice. Status: ${resp.statusCode}\n${resp.body}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => isSavingInvoice = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Error generating invoice: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _productGrid() {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 52,
            color: Colors.white,
            child: Row(
              children: [
                IconButton(icon: Icon(Icons.settings), onPressed: () {}),
                IconButton(icon: Icon(Icons.view_list), onPressed: () {}),
                IconButton(icon: Icon(Icons.grid_view), onPressed: () {}),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search products by name, code or barcode",
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                    ),
                  ),
                ),
                IconButton(icon: Icon(Icons.search), onPressed: () {}),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: GridView.builder(
                itemCount: filteredInventory.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, idx) {
                  final prod = filteredInventory[idx];
                  return GestureDetector(
                    onTap: () => _addToCart(prod),
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 36,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _categoryColor(prod['category']),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                            ),
                            child: Center(
                              child: Text(
                                prod['category'] ?? '',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Expanded(
                            child: prod['image'] != null
                                ? Image.network(prod['image'], height: 48, fit: BoxFit.contain)
                                : Icon(Icons.fastfood, size: 48, color: Colors.grey[400]),
                          ),
                          Text(prod['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(_parseDouble(prod['price']).toStringAsFixed(2),
                              style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            height: 42,
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Page 1 / 1", style: TextStyle(color: Colors.grey[700])),
                IconButton(icon: Icon(Icons.home, color: Colors.grey[600]), onPressed: () {}),
                IconButton(icon: Icon(Icons.arrow_back_ios, color: Colors.grey[600]), onPressed: () {}),
                IconButton(icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]), onPressed: () {}),
                SizedBox(width: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'Drink':
        return Colors.blue;
      case 'Food':
        return Colors.deepPurple;
      case 'Breakfast':
        return Colors.brown;
      case 'Salad':
        return Colors.orange;
      default:
        return Colors.grey[400]!;
    }
  }

  Widget _billRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Scaffold(body: Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red))));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        child: Row(
          children: [
            _productGrid(),
            _cartPreview(),
          ],
        ),
      ),
    );
  }
}