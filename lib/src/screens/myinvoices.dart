// lib/src/screens/invoices_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../consts.dart';
import '../blocs/invoice/InvoiceBloc.dart';
import '../blocs/invoice/InvoiceEvent.dart';
import '../blocs/invoice/InvoiceState.dart';
import '../repositories/invoice_repository.dart';
import '../services/invoice_service.dart';
import '../ui/invoice_shimmer.dart';
import '../ui/invoice_card.dart';
import '../models/invoice_model.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  late InvoiceBloc _bloc;
  final TextEditingController _searchCtrl = TextEditingController();
  String searchQuery = '';

  int page = 1;
  final int limit = 10;
  String? fromDate;
  String? toDate;

  String storeId = '';
  String branch = '';

  @override
  void initState() {
    super.initState();
    // Standardized service initialization using the central ApiClient
    final svc = InvoiceService();
    final repo = InvoiceRepository(service: svc);
    _bloc = InvoiceBloc(repository: repo);
    _initAndLoad();
    _searchCtrl.addListener(() {
      setState(() {
        searchQuery = _searchCtrl.text.trim();
      });
    });
  }

  Future<void> _initAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    storeId = prefs.getString('store_id') ?? '';
    branch = prefs.getString('branch') ?? '';
    _loadInvoices();
  }

  void _loadInvoices() {
    if (storeId.isEmpty || branch.isEmpty) return;
    _bloc.add(LoadInvoices(storeId: storeId, branch: branch, page: page, limit: limit, fromDate: fromDate, toDate: toDate));
  }

  @override
  void dispose() {
    _bloc.close();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<InvoiceModel> _filter(List<InvoiceModel> list) {
    if (searchQuery.isEmpty) return list;
    final q = searchQuery.toLowerCase();
    return list.where((inv) {
      final num = inv.invoiceNumber.toLowerCase();
      final cust = inv.customerName.toLowerCase();
      final email = inv.customerEmail.toLowerCase();
      final phone = inv.customerPhone.toLowerCase();
      return num.contains(q) || cust.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
  }

  void _showInvoicePreview(InvoiceModel inv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 48, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
                  Row(
                    children: [
                      const Expanded(child: Text('Invoice Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      IconButton(icon: const Icon(Icons.print), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Print not implemented')))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _previewHeader(inv),
                  const SizedBox(height: 12),
                  _previewItems(inv),
                  const SizedBox(height: 12),
                  _previewTotals(inv),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: ElevatedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewHeader(InvoiceModel invoice) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Invoice #: ${invoice.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text('Date: ${invoice.date}'),
      const SizedBox(height: 8),
      Text('Customer: ${invoice.customerName}'),
      if (invoice.customerPhone.isNotEmpty) ...[const SizedBox(height: 4), Text('Phone: ${invoice.customerPhone}')],
      if (invoice.customerEmail.isNotEmpty) ...[const SizedBox(height: 4), Text('Email: ${invoice.customerEmail}')],
    ]);
  }

  Widget _previewItems(InvoiceModel invoice) {
    final items = invoice.items;
    if (items.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(invoice.raw['description']?.toString() ?? '')]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(6)),
        child: Column(children: items.map((it) {
          final desc = it['description'] ?? it['name'] ?? it['title'] ?? '';
          final qty = it['qty'] ?? it['quantity'] ?? 1;
          final price = it['price'] ?? it['unit_price'] ?? it['rate'] ?? it['amount'] ?? '';
          final lineTotal = it['total'] ?? (price is num && qty is num ? (price * qty) : price);
          return ListTile(dense: true, title: Text(desc.toString()), subtitle: Text('Qty: ${qty ?? ''}'), trailing: Text('${lineTotal ?? price ?? ''}'));
        }).toList()),
      ),
    ]);
  }

  Widget _previewTotals(InvoiceModel invoice) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Row(children: [const Expanded(child: Text('Subtotal')), Text(invoice.subtotal.toString())]),
      const SizedBox(height: 6),
      Row(children: [const Expanded(child: Text('Tax')), Text(invoice.tax.toString())]),
      const SizedBox(height: 6),
      Row(children: [const Expanded(child: Text('Discount')), Text(invoice.discount.toString())]),
      const Divider(),
      Row(children: [const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))), Text(invoice.total.toString(), style: const TextStyle(fontWeight: FontWeight.bold))]),
    ]);
  }

  Widget _buildFilters() {
    final fromCtrl = TextEditingController(text: fromDate ?? '');
    final toCtrl = TextEditingController(text: toDate ?? '');
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: TextField(controller: _searchCtrl, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search invoices', border: OutlineInputBorder(), isDense: true)),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 120, child: TextField(controller: fromCtrl, decoration: const InputDecoration(labelText: 'From', hintText: 'YYYY-MM-DD', isDense: true), onChanged: (v) => fromDate = v)),
          const SizedBox(width: 8),
          SizedBox(width: 120, child: TextField(controller: toCtrl, decoration: const InputDecoration(labelText: 'To', hintText: 'YYYY-MM-DD', isDense: true), onChanged: (v) => toDate = v)),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: () { page = 1; _loadInvoices(); }, child: const Text('Filter')),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildPagination(InvoiceState state) {
    int currentPage = 1;
    if (state is InvoiceLoadSuccess) currentPage = state.page;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(children: [
        Text("Page $currentPage"),
        const Spacer(),
        IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: currentPage > 1 ? () { setState(() => page--); _loadInvoices(); } : null),
        IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: state is InvoiceLoadSuccess && state.invoices.length == limit ? () { setState(() => page++); _loadInvoices(); } : null),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InvoiceBloc>.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('My Invoices')),
        body: Column(
          children: [
            _buildFilters(),
            BlocBuilder<InvoiceBloc, InvoiceState>(
              builder: (context, state) {
                Widget pagination = _buildPagination(state);
                return pagination;
              },
            ),
            Expanded(
              child: BlocBuilder<InvoiceBloc, InvoiceState>(
                builder: (context, state) {
                  if (state is InvoiceLoadInProgress || state is InvoiceInitial) {
                    return const InvoiceShimmer();
                  } else if (state is InvoiceLoadFailure) {
                    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(state.message, style: const TextStyle(color: Colors.red)), const SizedBox(height: 8), ElevatedButton(onPressed: _loadInvoices, child: const Text('Retry'))]));
                  } else if (state is InvoiceLoadSuccess) {
                    final list = _filter(state.invoices);
                    if (list.isEmpty) return const Center(child: Text('No invoices found.'));
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, idx) {
                        final inv = list[idx];
                        return InvoiceCard(invoice: inv, onTap: () => _showInvoicePreview(inv));
                      },
                    );
                  } else {
                    return const Center(child: Text('Unexpected state'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}