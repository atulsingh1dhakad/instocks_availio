// lib/src/screens/billing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../blocs/billing/BillingBloc.dart';
import '../blocs/billing/BillingEvent.dart';
import '../blocs/billing/BillingState.dart';
import '../models/inventory_items.dart';
import '../repositories/billing_repository.dart';
import '../services/billing_service.dart';
import '../ui/product_tile.dart';
import '../ui/cart_panel.dart';
import '../ui/billing_shimmer.dart';
import '../models/cart_item.dart';
import '../../consts.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  late BillingBloc _billingBloc;
  String storeId = '';
  String branch = '';
  String customerName = '';
  String customerPhone = '';
  String paymentMode = '';
  bool isProceeding = false;

  @override
  void initState() {
    super.initState();
    final service = BillingService(apiUrl: API_URL, apiToken: API_TOKEN);
    final repo = BillingRepository(service: service);
    _billingBloc = BillingBloc(repository: repo);
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    storeId = prefs.getString('store_id') ?? '';
    branch = prefs.getString('branch') ?? '';
    // seed customer name if stored
    customerName = prefs.getString('customer_name') ?? '';
    customerPhone = prefs.getString('customer_phone') ?? '';
    _billingBloc.add(LoadInventory(storeId: storeId, branch: branch));
  }

  @override
  void dispose() {
    _billingBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BillingBloc>.value(
      value: _billingBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAF7),
        body: SafeArea(
          child: Row(
            children: [
              // left panel: inventory grid & toolbar
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 52,
                      color: Colors.white,
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.view_list), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.grid_view), onPressed: () {}),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Search products by name, code or barcode",
                                  border: InputBorder.none,
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                ),
                                onChanged: (val) {
                                  // local filtering is handled in UI by filtering the displayed inventory
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                        ],
                      ),
                    ),
                    Expanded(
                      child: BlocConsumer<BillingBloc, BillingState>(
                        listener: (context, state) {
                          if (state is InvoiceInProgress) {
                            setState(() => isProceeding = true);
                          } else if (state is InvoiceSuccess) {
                            setState(() => isProceeding = false);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice generated successfully')));
                          } else if (state is InvoiceFailure) {
                            setState(() => isProceeding = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                          } else if (state is BillingFailure) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                          }
                        },
                        builder: (context, state) {
                          if (state is BillingLoading || state is BillingInitial) {
                            return const BillingShimmer();
                          } else if (state is BillingFailure) {
                            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                          } else if (state is BillingLoadSuccess) {
                            final inventory = state.inventory;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                              child: GridView.builder(
                                itemCount: inventory.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 1.1,
                                ),
                                itemBuilder: (context, idx) {
                                  final InventoryItem prod = inventory[idx];
                                  return ProductTile(
                                    item: prod,
                                    onTap: () {
                                      _billingBloc.add(AddToCart(prod));
                                    },
                                  );
                                },
                              ),
                            );
                          } else {
                            return const Center(child: Text('Unexpected state'));
                          }
                        },
                      ),
                    ),
                    Container(
                      height: 42,
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Page 1 / 1'),
                          IconButton(icon: const Icon(Icons.home), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: () {}),
                          const SizedBox(width: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // right panel: cart
              BlocBuilder<BillingBloc, BillingState>(
                builder: (context, state) {
                  List<CartItem> cart = [];
                  double subtotal = 0.0;
                  double tax = 0.0;
                  double total = 0.0;
                  if (state is BillingLoadSuccess) {
                    cart = state.cart;
                    subtotal = state.subtotal;
                    tax = state.tax;
                    total = state.total;
                  }

                  return CartPanel(
                    cart: cart,
                    subtotal: subtotal,
                    tax: tax,
                    total: total,
                    customerName: customerName,
                    customerPhone: customerPhone,
                    onCustomerNameChanged: (val) {
                      setState(() => customerName = val);
                    },
                    onCustomerPhoneChanged: (val) {
                      setState(() => customerPhone = val);
                    },
                    onClearCart: () {
                      for (final c in cart) {
                        _billingBloc.add(RemoveFromCart(c.product.id));
                      }
                    },
                    onIncrease: (productId) => _billingBloc.add(IncreaseQty(productId)),
                    onDecrease: (productId) => _billingBloc.add(DecreaseQty(productId)),
                    onPaymentModeChanged: (mode) => setState(() => paymentMode = mode),
                    onProceed: () {
                      if (customerName.trim().isEmpty) {
                        // show dialog to enter customer name
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            String tmpName = '';
                            String tmpPhone = '';
                            return AlertDialog(
                              title: const Text('Enter Customer Details'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(decoration: const InputDecoration(labelText: 'Customer Name'), onChanged: (v) => tmpName = v),
                                  const SizedBox(height: 8),
                                  TextField(decoration: const InputDecoration(labelText: 'Phone (optional)'), keyboardType: TextInputType.phone, onChanged: (v) => tmpPhone = v),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () {
                                    if (tmpName.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provide customer name')));
                                      return;
                                    }
                                    Navigator.of(context).pop();
                                    setState(() {
                                      customerName = tmpName.trim();
                                      customerPhone = tmpPhone.trim();
                                    });
                                    _billingBloc.add(ProceedInvoice(customerName: customerName, customerPhone: customerPhone, paymentMode: paymentMode));
                                  },
                                  child: const Text('Save & Proceed'),
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        _billingBloc.add(ProceedInvoice(customerName: customerName, customerPhone: customerPhone, paymentMode: paymentMode));
                      }
                    },
                    isProceeding: isProceeding, paymentMode: '',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}