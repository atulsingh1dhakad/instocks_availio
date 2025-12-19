// lib/src/ui/order_shimmer.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class OrderShimmer extends StatelessWidget {
  const OrderShimmer({super.key});

  Widget _row() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 40, height: 40, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: double.infinity, color: Colors.white),
                const SizedBox(height: 6),
                Container(height: 10, width: 140, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(height: 12, width: 70, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 30, width: 70, color: Colors.white),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(6, (index) => _row()),
      ),
    );
  }
}