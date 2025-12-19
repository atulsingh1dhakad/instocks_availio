// lib/src/ui/recycle_shimmer.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class RecycleShimmer extends StatelessWidget {
  const RecycleShimmer({super.key});

  Widget _row() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 50, height: 50, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                Container(height: 12, width: double.infinity, color: Colors.white),
                const SizedBox(height: 8),
                Container(height: 10, width: 140, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(height: 24, width: 24, color: Colors.white),
              const SizedBox(height: 8),
              Container(height: 24, width: 24, color: Colors.white),
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
        children: List.generate(6, (_) => _row()),
      ),
    );
  }
}