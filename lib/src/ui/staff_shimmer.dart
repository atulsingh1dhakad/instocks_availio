// lib/src/ui/staff_shimmer.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class StaffShimmer extends StatelessWidget {
  const StaffShimmer({super.key});

  Widget _row() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Container(width: 56, height: 56, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 14, width: 160, color: Colors.white),
                const SizedBox(height: 8),
                Container(height: 12, width: 120, color: Colors.white),
              ]),
            ),
            const SizedBox(width: 12),
            Column(children: [
              Container(height: 24, width: 80, color: Colors.white),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100, child: Column(children: List.generate(6, (_) => _row())));
  }
}