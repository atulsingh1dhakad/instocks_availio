import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../consts.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String storeId = '';
  String branch = '';
  bool isLoading = true;
  String selectedStatus = 'pending'; // Default: Orders tab = pending
  int page = 1;
  int limit = 10;
  List<Map<String, dynamic>> orders = [];
  String? errorMessage;

  static const String apiToken = '0ff738d516ce887efe7274d43acd8043';

  final List<Map<String, String>> statusTabs = [
    {'label': 'New Orders', 'value': 'pending'},
    {'label': 'Accepted Orders', 'value': 'accepted'},
    {'label': 'Rejected Orders', 'value': 'rejected'},
    {'label': 'Completed Orders', 'value': 'delivered'},
  ];

  @override
  void initState() {
    super.initState();
    fetchStoreInfoAndOrders();
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

  // Helper to extract the "important" message from server responses
  String _parseImportantMessage(String body) {
    if (body.trim().isEmpty) return 'Something went wrong';
    try {
      final decoded = json.decode(body);
      if (decoded is String) return decoded;
      if (decoded is Map) {
        if (decoded['detail'] != null) return decoded['detail'].toString();
        if (decoded['message'] != null) {
          final msg = decoded['message'];
          if (msg is String) return msg;
          if (msg is Map) {
            // collect first meaningful message
            for (final v in msg.values) {
              if (v is List) return v.join(', ');
              if (v is String) return v;
            }
          }
          if (msg is List) return msg.join(', ');
        }
        if (decoded['errors'] != null) {
          final errs = decoded['errors'];
          if (errs is String) return errs;
          if (errs is Map) {
            final parts = <String>[];
            errs.forEach((k, v) {
              if (v is List) parts.add('$k: ${v.join(", ")}');
              else parts.add('$k: $v');
            });
            return parts.join(' • ');
          }
          if (errs is List) return errs.join(', ');
        }
        // fallback: return the first non-empty value
        for (final v in decoded.values) {
          if (v is String && v.trim().isNotEmpty) return v;
          if (v is List && v.isNotEmpty) return v.first.toString();
        }
      } else if (decoded is List && decoded.isNotEmpty) {
        return decoded.first.toString();
      }
    } catch (_) {
      // body isn't JSON - fall through
    }
    // final fallback: return the plain body, trimmed and cleaned
    final cleaned = body.replaceAll(RegExp(r'[\{\}\[\]\"]'), '').trim();
    return cleaned.isEmpty ? 'Something went wrong' : cleaned;
  }

  Future<void> fetchStoreInfoAndOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    storeId = prefs.getString('store_id') ?? '';
    branch = prefs.getString('branch') ?? '';
    await fetchOrders(selectedStatus);
  }

  Future<void> fetchOrders(String status) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    if (status == 'pending') {
      // Use the old pending endpoint
      final String url = ('${API_URL}order/store-pending-orders/');
      try {
        final headers = await _getAuthHeaders();
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({
            "store_id": storeId,
            "branch": branch,
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          // If backend returns a 'detail' telling there are no pending orders,
          // show that text only.
          if (data is Map && data.containsKey('detail')) {
            setState(() {
              orders = [];
              errorMessage = data['detail']?.toString() ?? 'No pending orders found';
              isLoading = false;
            });
            return;
          }

          setState(() {
            if (data['pending_orders'] is List) {
              orders = List<Map<String, dynamic>>.from(
                data['pending_orders'].map((order) => {
                  "label": "Order ID: ${order["order_id"] ?? ""}",
                  "leftStatus": order["payment_status"] ?? "",
                  "middle": "₹${order["total_amount"] ?? ""}",
                  "rightStatus": order["order_status"] ?? "",
                  "order_id": order["order_id"],
                  "raw": order,
                }),
              );
              errorMessage = null;
            } else {
              orders = [];
              // if API returns an empty list without detail, show a friendly message
              errorMessage = 'No pending orders found';
            }
            isLoading = false;
          });
        } else {
          final important = _parseImportantMessage(response.body);
          setState(() {
            orders = [];
            errorMessage = important;
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          orders = [];
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    } else if (status == 'accepted' || status == 'rejected' || status == 'delivered') {
      // Use the /order/orders-by-status endpoint for accepted/rejected/delivered
      final String url = ('${API_URL}order/orders-by-status');
      try {
        final headers = await _getAuthHeaders();
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({
            "status": status,
            "store_id": storeId,
            "branch": branch,
            "page": page,
            "limit": limit,
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // If API returns a 'detail' message (e.g., "No accepted orders found"), show it.
          if (data is Map && data.containsKey('detail')) {
            setState(() {
              orders = [];
              errorMessage = data['detail']?.toString() ?? 'No orders found';
              isLoading = false;
            });
            return;
          }

          setState(() {
            final ordersList = data['orders'];
            if (ordersList is List) {
              orders = List<Map<String, dynamic>>.from(
                ordersList.map((order) => {
                  "label": "Order ID: ${order["order_id"] ?? ""}",
                  "leftStatus": order["payment_status"] ?? "",
                  "middle": "₹${order["total_amount"] ?? ""}",
                  "rightStatus": order["order_status"] ?? "",
                  "order_id": order["order_id"],
                  "raw": order,
                }),
              );
              errorMessage = null;
            } else {
              orders = [];
              errorMessage = 'No orders found';
            }
            isLoading = false;
          });
        } else {
          final important = _parseImportantMessage(response.body);
          setState(() {
            orders = [];
            errorMessage = important;
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          orders = [];
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> acceptOrder(String orderId) async {
    final url = '${API_URL}order/accept-order';
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          "order_id": orderId,
          "store_id": storeId,
          "branch": branch,
        }),
      );
      if (response.statusCode == 200) {
        fetchOrders(selectedStatus);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order accepted!")));
      } else {
        final important = _parseImportantMessage(response.body);
        setState(() {
          isLoading = false;
          errorMessage = important;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(important)));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> rejectOrder(String orderId, String reason) async {
    final url = '${API_URL}order/reject-order';
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          "order_id": orderId,
          "store_id": storeId,
          "branch": branch,
          "reason": reason,
        }),
      );
      if (response.statusCode == 200) {
        fetchOrders(selectedStatus);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order rejected!")));
      } else {
        final important = _parseImportantMessage(response.body);
        setState(() {
          isLoading = false;
          errorMessage = important;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(important)));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showRejectDialog(String orderId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Order'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: "Reason for rejection"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason!')),
                );
                return;
              }
              Navigator.of(ctx).pop();
              rejectOrder(orderId, reason);
            },
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Row(
      children: [
        for (int i = 0; i < statusTabs.length; i++)
          GestureDetector(
            onTap: () {
              setState(() {
                selectedStatus = statusTabs[i]['value']!;
              });
              fetchOrders(selectedStatus);
            },
            child: _tab3d(
              statusTabs[i]['label']!,
              selectedStatus == statusTabs[i]['value'],
            ),
          ),
        const Spacer(),
        _iconCircle(Icons.search),
        const SizedBox(width: 10),
        _iconCircle(Icons.person),
        const SizedBox(width: 10),
        _iconCircle(Icons.notifications_none),
        const SizedBox(width: 10),
        _iconCircle(Icons.settings),
      ],
    );
  }

  // 3D Tab Button
  Widget _tab3d(String text, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      margin: EdgeInsets.only(right: 12, top: selected ? 2 : 6, bottom: selected ? 6 : 2),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF49A97C) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: const Color(0xFF49A97C).withOpacity(0.35),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 1,
            )
          else
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(0, 2),
              blurRadius: 6,
              spreadRadius: 1,
            )
        ],
        border: Border.all(color: selected ? const Color(0xFF38875F) : Colors.grey.shade300, width: selected ? 2 : 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF686C7A),
          fontWeight: FontWeight.w700,
          fontSize: 16,
          shadows: selected
              ? [
            Shadow(
              color: const Color(0xFF38875F).withOpacity(0.13),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ]
              : [],
        ),
      ),
    );
  }

  Widget _iconCircle(IconData icon) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      radius: 18,
      child: Icon(icon, color: Colors.grey.shade500, size: 20),
    );
  }

  Widget _buildHeaderSearch() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text("Order ID", style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          const Spacer(),
          Icon(Icons.search, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Icon(Icons.filter_alt_outlined, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildCustomerFilter() {
    return Row(
      children: [
        Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text("Customer", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF49A97C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: const [
              Text("Customer Rate ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text("Completed", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              data["label"]?.toString() ?? '',
              style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 10),
          _statusButton(data["leftStatus"]?.toString() ?? '', Colors.red.shade200, Colors.red),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: Text(
              data["middle"]?.toString() ?? '',
              style: TextStyle(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          _statusButton(data["rightStatus"]?.toString() ?? '', Colors.blue.shade100, const Color(0xFF6C8AE3)),
          const SizedBox(width: 10),
          if (selectedStatus == 'pending') ...[
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                acceptOrder(data["order_id"].toString());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF49A97C),
                foregroundColor: Colors.white,
                minimumSize: const Size(65, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text("Accept"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                _showRejectDialog(data["order_id"].toString());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                minimumSize: const Size(65, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: const Text("Reject"),
            ),
          ]
        ],
      ),
    );
  }

  Widget _statusButton(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTabBar(),
              const SizedBox(height: 18),
              _buildHeaderSearch(),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 4),
              _buildCustomerFilter(),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                    ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
                    : orders.isEmpty
                    ? const Center(child: Text("No orders found"))
                    : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, idx) {
                    return _buildOrderRow(orders[idx]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}