// lib/src/ui/invoice_shimmer.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class InvoiceShimmer extends StatelessWidget {
  const InvoiceShimmer({super.key});

  Widget _tile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Card(
          child: ListTile(
            title: Container(height: 14, width: 150, color: Colors.white),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Container(height: 10, width: 200, color: Colors.white),
                const SizedBox(height: 4),
                Container(height: 10, width: 120, color: Colors.white),
              ],
            ),
            trailing: Container(width: 16, height: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(itemCount: 6, itemBuilder: (context, _) => _tile());
  }
}