// lib/src/ui/billing_shimmer.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BillingShimmer extends StatelessWidget {
  const BillingShimmer({super.key});

  Widget _tile() {
    return Card(
      child: Column(
        children: [
          Container(height: 36, color: Colors.white),
          Expanded(child: Container(color: Colors.white)),
          Container(height: 20, color: Colors.white),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: GridView.count(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        padding: const EdgeInsets.all(12),
        children: List.generate(8, (_) => _tile()),
      ),
    );
  }
}