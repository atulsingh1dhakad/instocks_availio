import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:instockavailio/consts.dart';

// Add shimmer package to your pubspec.yaml:
// shimmer: ^2.0.0
import 'package:shimmer/shimmer.dart';

class MyInvoices extends StatefulWidget {
  const MyInvoices({super.key});

  @override
  State<MyInvoices> createState() => _MyInvoicesState();
}

class _MyInvoicesState extends State<MyInvoices> {
  List<Map<String, dynamic>> invoices = [];
  bool isLoading = true;
  String? errorMessage;

  // Filters and pagination
  int page = 1;
  int limit = 10;
  String? fromDate;
  String? toDate;

  // For store and branch
  String? storeId;
  String? branch;

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  String searchQuery = '';

  static const String apiToken = '0ff738d516ce887efe7274d43acd8043';

  @override
  void initState() {
    super.initState();
    fetchStoreAndBranch();
    _searchCtrl.addListener(() {
      setState(() {
        searchQuery = _searchCtrl.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('access_token');
    final String? tokenTypeRaw = prefs.getString('token_type');
    final String tokenType = (tokenTypeRaw ?? 'Bearer').trim();
    final String? useAccessToken =
    accessToken != null && accessToken.trim().isNotEmpty ? accessToken.trim() : null;
    final String authorizationHeader =
        '${tokenType.isNotEmpty ? tokenType[0].toUpperCase() + tokenType.substring(1).toLowerCase() : 'Bearer'} ${useAccessToken ?? ""}';

    return {
      'Content-Type': 'application/json',
      'x-api-token': apiToken,
      'Authorization': authorizationHeader,
    };
  }

  Future<void> fetchStoreAndBranch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? accessToken = prefs.getString('access_token');
      final String? tokenTypeRaw = prefs.getString('token_type');
      final String tokenType = (tokenTypeRaw ?? 'Bearer').trim();
      final String? useAccessToken =
      accessToken != null && accessToken.trim().isNotEmpty ? accessToken.trim() : null;
      final String authorizationHeader =
          '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} ${useAccessToken ?? ""}';

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
          isLoading = false;
        });
        return;
      }

      final userJson = json.decode(userResp.body);
      storeId = userJson['store_id']?.toString();
      branch = userJson['branch']?.toString();

      fetchInvoices();
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  Future<void> fetchInvoices() async {
    if (storeId == null || branch == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final headers = await _getAuthHeaders();

      final Map<String, dynamic> body = {
        "store_id": storeId!,
        "branch": branch!,
        "page": page,
        "limit": limit,
        if (fromDate != null && fromDate!.isNotEmpty) "from_date": fromDate,
        if (toDate != null && toDate!.isNotEmpty) "to_date": toDate,
      };

      final uri = Uri.parse('${API_URL}invoices/store-invoices');

      final resp = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (resp.statusCode != 200) {
        setState(() {
          errorMessage = "Failed to load invoices: ${resp.statusCode}\n${resp.body}";
          isLoading = false;
        });
        return;
      }

      final data = json.decode(resp.body);

      List<Map<String, dynamic>> invoiceList = [];
      if (data is Map && data["invoices"] is List) {
        invoiceList = List<Map<String, dynamic>>.from(data["invoices"]);
      } else if (data is List) {
        // Some APIs return a list directly
        invoiceList = List<Map<String, dynamic>>.from(data);
      }

      setState(() {
        invoices = invoiceList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching invoices: $e";
        isLoading = false;
      });
    }
  }

  // Client-side filtered invoices based on searchQuery
  List<Map<String, dynamic>> get filteredInvoices {
    if (searchQuery.isEmpty) return invoices;
    final q = searchQuery.toLowerCase();
    return invoices.where((inv) {
      final invNum = (inv['invoice_number'] ?? inv['id'] ?? '').toString().toLowerCase();
      final cust = (inv['customer_name'] ?? inv['customer'] ?? '').toString().toLowerCase();
      final email = (inv['customer_email'] ?? '').toString().toLowerCase();
      final phone = (inv['customer_phone'] ?? inv['phone'] ?? '').toString().toLowerCase();
      return invNum.contains(q) || cust.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
  }

  Widget _buildInvoiceList() {
    if (isLoading) {
      // Show shimmer while loading
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (context, idx) => _shimmerInvoiceTile(),
      );
    }
    if (errorMessage != null) {
      return Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)));
    }

    final listToShow = filteredInvoices;

    if (listToShow.isEmpty) {
      return const Center(child: Text("No invoices found."));
    }
    return ListView.builder(
      itemCount: listToShow.length,
      itemBuilder: (context, idx) {
        final invoice = listToShow[idx];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: ListTile(
            title: Text('Invoice #${invoice["invoice_number"] ?? invoice["id"] ?? ""}'),
            subtitle: Text(
              'Customer: ${invoice["customer_name"] ?? invoice["customer"] ?? ""}\n'
                  'Date: ${invoice["date"] ?? invoice["created_at"] ?? ""}\n'
                  'Total: ${invoice["total"] ?? invoice["amount"] ?? ""}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showInvoicePreview(invoice),
          ),
        );
      },
    );
  }

  Widget _shimmerInvoiceTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          child: ListTile(
            title: Container(height: 16, width: 120, color: Colors.white),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Container(height: 10, width: 180, color: Colors.white),
                const SizedBox(height: 5),
                Container(height: 10, width: 120, color: Colors.white),
                const SizedBox(height: 5),
                Container(height: 10, width: 80, color: Colors.white),
              ],
            ),
            trailing: Container(
              width: 16,
              height: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final fromDateController = TextEditingController(text: fromDate ?? "");
    final toDateController = TextEditingController(text: toDate ?? "");
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    labelText: "Search invoices",
                    hintText: "Invoice #, customer name, email or phone",
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: fromDateController,
                  decoration: const InputDecoration(
                    labelText: "From",
                    hintText: "YYYY-MM-DD",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => fromDate = value,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: toDateController,
                  decoration: const InputDecoration(
                    labelText: "To",
                    hintText: "YYYY-MM-DD",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => toDate = value,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    page = 1; // Reset to first page on filter
                  });
                  fetchInvoices();
                },
                child: const Text("Filter"),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Text("Page $page"),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: page > 1
                ? () {
              setState(() {
                page--;
              });
              fetchInvoices();
            }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: invoices.length == limit && !isLoading
                ? () {
              setState(() {
                page++;
              });
              fetchInvoices();
            }
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _showInvoicePreview(Map<String, dynamic> invoice) async {
    // Show a bottom sheet invoice preview — scrollable and keyboard-aware
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Invoice Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.print),
                          onPressed: () {
                            // Placeholder for printing/exporting
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Print not implemented')));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _previewHeader(invoice),
                    const SizedBox(height: 12),
                    _previewItems(invoice),
                    const SizedBox(height: 12),
                    _previewTotals(invoice),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _previewHeader(Map<String, dynamic> invoice) {
    final invoiceNumber = invoice['invoice_number'] ?? invoice['id'] ?? '';
    final date = invoice['date'] ?? invoice['created_at'] ?? '';
    final customerName = invoice['customer_name'] ?? invoice['customer'] ?? '';
    final customerPhone = invoice['customer_phone'] ?? invoice['phone'] ?? '';
    final customerEmail = invoice['customer_email'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invoice #: $invoiceNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Date: $date'),
        const SizedBox(height: 8),
        Text('Customer: $customerName'),
        if (customerPhone != null && customerPhone.toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Phone: $customerPhone'),
        ],
        if (customerEmail != null && customerEmail.toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Email: $customerEmail'),
        ],
      ],
    );
  }

  Widget _previewItems(Map<String, dynamic> invoice) {
    // Handle several possible shapes for invoice line items
    final dynamic itemsRaw = invoice['items'] ?? invoice['line_items'] ?? invoice['products'] ?? [];
    final List<Map<String, dynamic>> items = [];

    if (itemsRaw is List) {
      for (final it in itemsRaw) {
        if (it is Map) {
          items.add(Map<String, dynamic>.from(it));
        } else {
          items.add({'description': it.toString(), 'qty': 1, 'price': ''});
        }
      }
    }

    if (items.isEmpty) {
      // If no structured items available, try to show description/notes
      final desc = invoice['description'] ?? invoice['notes'] ?? invoice['note'] ?? '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(desc.toString()),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(6)),
          child: Column(
            children: items.map((it) {
              final desc = it['description'] ?? it['name'] ?? it['title'] ?? '';
              final qty = it['qty'] ?? it['quantity'] ?? it['qty'] == 0 ? it['qty'] : (it['quantity'] ?? 1);
              final price = it['price'] ?? it['unit_price'] ?? it['rate'] ?? it['amount'] ?? '';
              final lineTotal = it['total'] ?? (price is num && qty is num ? (price * qty) : null);
              return ListTile(
                dense: true,
                title: Text(desc.toString()),
                subtitle: Text('Qty: ${qty ?? ''}'),
                trailing: Text('${lineTotal ?? price ?? ''}'),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _previewTotals(Map<String, dynamic> invoice) {
    final subtotal = invoice['subtotal'] ?? invoice['sub_total'] ?? invoice['amount_before_tax'] ?? invoice['amount'] ?? 0;
    final tax = invoice['tax'] ?? invoice['tax_total'] ?? 0;
    final discount = invoice['discount'] ?? 0;
    final total = invoice['total'] ?? invoice['grand_total'] ?? invoice['amount'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          children: [
            const Expanded(child: Text('Subtotal')),
            Text(subtotal.toString()),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Expanded(child: Text('Tax')),
            Text(tax.toString()),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Expanded(child: Text('Discount')),
            Text(discount.toString()),
          ],
        ),
        const Divider(),
        Row(
          children: [
            const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
            Text(total.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Invoices"),
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildPagination(),
          Expanded(child: _buildInvoiceList()),
        ],
      ),
    );
  }
}