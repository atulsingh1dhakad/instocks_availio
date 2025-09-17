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

  static const String apiToken = '0ff738d516ce887efe7274d43acd8043';

  @override
  void initState() {
    super.initState();
    fetchStoreAndBranch();
  }

  Future<void> fetchStoreAndBranch() async {
    try {
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
      storeId = userJson['store_id'];
      branch = userJson['branch'];

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
      // DO NOT clear invoices here, so shimmer is visible, not 'no invoice found'
      // invoices = [];
    });

    try {
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
        headers: {
          'Content-Type': 'application/json',
          'x-api-token': apiToken,
          'Authorization': authorizationHeader,
        },
        body: jsonEncode(body),
      );

      if (resp.statusCode != 200) {
        setState(() {
          errorMessage =
          "Failed to load invoices: ${resp.statusCode}\n${resp.body}";
          isLoading = false;
        });
        return;
      }

      final data = json.decode(resp.body);

      List<Map<String, dynamic>> invoiceList = [];
      if (data is Map && data["invoices"] is List) {
        invoiceList = List<Map<String, dynamic>>.from(data["invoices"]);
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
    if (invoices.isEmpty) {
      return const Center(child: Text("No invoices found."));
    }
    return ListView.builder(
      itemCount: invoices.length,
      itemBuilder: (context, idx) {
        final invoice = invoices[idx];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: ListTile(
            title: Text('Invoice #${invoice["invoice_number"] ?? invoice["id"] ?? ""}'),
            subtitle: Text(
              'Customer: ${invoice["customer_name"] ?? ""}\n'
                  'Date: ${invoice["date"] ?? ""}\n'
                  'Total: ${invoice["total"] ?? ""}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Optionally, navigate to invoice detail
            },
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
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: TextField(
              controller: fromDateController,
              decoration: const InputDecoration(
                labelText: "From Date",
                hintText: "YYYY-MM-DD",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                fromDate = value;
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: TextField(
              controller: toDateController,
              decoration: const InputDecoration(
                labelText: "To Date",
                hintText: "YYYY-MM-DD",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                toDate = value;
              },
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
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchInvoices,
          )
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