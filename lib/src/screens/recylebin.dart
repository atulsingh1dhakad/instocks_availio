// lib/src/screens/recycle_bin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instockavailio/src/services/dashboard_service.dart';
import '../../consts.dart';
import '../blocs/recycle/RecycleBloc.dart';
import '../blocs/recycle/RecycleEvent.dart';
import '../blocs/recycle/RecycleState.dart';
import '../repositories/recycle_repository.dart';
import '../services/recycle_service.dart';
import '../ui/recycle_shimmer.dart';
import '../ui/recycle_card.dart';
import '../models/recycle_item.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  late RecycleBloc _bloc;

  @override
  void initState() {
    super.initState();
    final svc = RecycleService(apiUrl: API_URL, apiToken: DashboardService.apiToken);
    final repo = RecycleRepository(service: svc);
    _bloc = RecycleBloc(repository: repo);
    _bloc.add(LoadRecycleBin());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<bool?> _confirmDialog(String title, String content, String actionLabel, {Color actionColor = Colors.red}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: actionColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecycleBloc>.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recycle Bin', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            IconButton(icon: const Icon(Icons.refresh, color: Colors.black), onPressed: () => _bloc.add(LoadRecycleBin())),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: 'Delete All',
              onPressed: () async {
                final ok = await _confirmDialog('Delete All Products', 'Permanently delete all products in recycle bin? This cannot be undone.', 'Delete All');
                if (ok == true) _bloc.add(DeleteAllProductsEvent());
              },
            ),
          ],
        ),
        body: BlocConsumer<RecycleBloc, RecycleState>(
          listener: (context, state) {
            if (state is RecycleActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is RecycleActionFailure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is RecycleLoadInProgress || state is RecycleInitial) {
              return const SingleChildScrollView(child: RecycleShimmer());
            } else if (state is RecycleLoadFailure) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(state.message, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () => _bloc.add(LoadRecycleBin()), child: const Text('Retry')),
                ]),
              );
            } else if (state is RecycleLoadSuccess) {
              final items = state.items;
              if (items.isEmpty) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    // Replace with your asset if you have one
                    SizedBox(height: 120, child: Image.asset('assets/images/emptybin.png', fit: BoxFit.contain)),
                    const SizedBox(height: 12),
                    const Text('No products in recycle bin.'),
                  ]),
                );
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, idx) {
                  final RecycleItem item = items[idx];
                  return RecycleCard(
                    item: item,
                    onRestore: () async {
                      final ok = await _confirmDialog('Restore Product', 'Restore "${item.name}" back to inventory?', 'Restore', actionColor: Colors.green);
                      if (ok == true) _bloc.add(RestoreProductEvent(item.productId));
                    },
                    onDelete: () async {
                      final ok = await _confirmDialog('Delete Product', 'Permanently delete "${item.name}"?', 'Delete', actionColor: Colors.red);
                      if (ok == true) _bloc.add(DeleteProductEvent(item.productId));
                    },
                  );
                },
              );
            } else {
              return const Center(child: Text('Unexpected state'));
            }
          },
        ),
      ),
    );
  }
}