// lib/src/ui/profile_shimmer.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  Widget _line({double width = 160, double height = 18}) => Container(width: width, height: height, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 96, height: 96, color: Colors.white),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _line(width: 200, height: 28),
                        const SizedBox(height: 8),
                        Row(children: [_line(width: 80, height: 24), const SizedBox(width: 8), _line(width: 80, height: 24)]),
                        const SizedBox(height: 12),
                        _line(width: 220, height: 18),
                        const SizedBox(height: 6),
                        _line(width: 120, height: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(color: Colors.white, padding: const EdgeInsets.all(16), child: _line(width: 300, height: 16)),
            const SizedBox(height: 16),
            Container(color: Colors.white, padding: const EdgeInsets.all(16), child: _line(width: 300, height: 16)),
          ],
        ),
      ),
    );
  }
}