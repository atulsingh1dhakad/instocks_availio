// lib/src/screens/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instockavailio/src/screens/recylebin.dart';
import '../../consts.dart';
import '../blocs/order/order_bloc.dart';
import '../blocs/order/order_event.dart';
import '../blocs/order/order_state.dart';
import '../repositories/order_repository.dart';
import '../services/order_service.dart';
import '../ui/order_card.dart';
import '../ui/order_shimmer.dart';
import '../models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late OrderBloc _orderBloc;
  String selectedStatus = 'pending';
  String storeId = '';
  String branch = '';

  final List<Map<String, String>> statusTabs = [
    {'label': 'New Orders', 'value': 'pending'},
    {'label': 'Accepted Orders', 'value': 'accepted'},
    {'label': 'Rejected Orders', 'value': 'rejected'},
    {'label': 'Completed Orders', 'value': 'delivered'},
  ];

  @override
  void initState() {
    super.initState();
    final service = OrderService(apiToken: API_TOKEN, apiUrl: API_URL);
    final repo = OrderRepository(service: service);
    _orderBloc = OrderBloc(repository: repo);
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    storeId = prefs.getString('store_id') ?? '';
    branch = prefs.getString('branch') ?? '';
    _loadOrders();
  }

  void _loadOrders() {
    _orderBloc.add(LoadOrders(status: selectedStatus, storeId: storeId, branch: branch));
  }

  @override
  void dispose() {
    _orderBloc.close();
    super.dispose();
  }

  Widget _tab3d(String text, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStatus = statusTabs.firstWhere((t) => t['label'] == text)['value']!;
        });
        _loadOrders();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: EdgeInsets.only(right: 12, top: selected ? 2 : 6, bottom: selected ? 6 : 2),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF49A97C) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? const Color(0xFF38875F) : Colors.grey.shade300, width: selected ? 2 : 1),
        ),
        child: Text(text, style: TextStyle(color: selected ? Colors.white : const Color(0xFF686C7A), fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }

  void _showRejectDialog(String orderId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Order'),
        content: TextField(controller: reasonController, decoration: const InputDecoration(labelText: "Reason for rejection")),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a reason!')));
                return;
              }
              Navigator.of(ctx).pop();
              _orderBloc.add(RejectOrderEvent(orderId: orderId, storeId: storeId, branch: branch, reason: reason));
            },
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderBloc>.value(
      value: _orderBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FB),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // tabs row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final t in statusTabs) _tab3d(t['label']!, selectedStatus == t['value']),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // simple header search placeholder
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(children: [Text("Order ID", style: TextStyle(fontSize: 16, color: Colors.grey.shade700)), const Spacer(), Icon(Icons.search, color: Colors.grey.shade400)]),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: BlocConsumer<OrderBloc, OrderState>(
                    listener: (context, state) {
                      if (state is OrderActionSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                      } else if (state is OrderActionFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                      }
                    },
                    builder: (context, state) {
                      if (state is OrdersLoadInProgress || state is OrdersInitial) {
                        return const SingleChildScrollView(child: Padding(padding: EdgeInsets.only(top: 8.0), child: OrderShimmer()));
                      } else if (state is OrdersLoadFailure) {
                        return Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(state.message, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                            ElevatedButton(onPressed: _loadOrders, child: const Text('Retry')),
                          ]),
                        );
                      } else if (state is OrdersLoadSuccess) {
                        final list = state.orders.map((o) => o.toMapForList()).toList();
                        if (list.isEmpty) return const Center(child: Text('No orders found'));
                        return ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, idx) {
                            final item = list[idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: OrderCard(
                                item: item,
                                isPending: selectedStatus == 'pending',
                                onAccept: selectedStatus == 'pending'
                                    ? () => _orderBloc.add(AcceptOrderEvent(orderId: item['order_id'].toString(), storeId: storeId, branch: branch))
                                    : null,
                                onReject: selectedStatus == 'pending' ? () => _showRejectDialog(item['order_id'].toString()) : null,
                              ),
                            );
                          },
                        );
                      } else {
                        return const Center(child: Text('Unexpected state'));
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}