import 'package:flutter/material.dart';
import '../reusable/shimmer_loading.dart';

class DashboardSkeleton extends StatelessWidget {
  final int cardCount;
  const DashboardSkeleton({Key? key, this.cardCount = 4}) : super(key: key);

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
      child: Row(
        children: const [
          ShimmerBlock(width: 220, height: 28, borderRadius: BorderRadius.all(Radius.circular(8))),
          Spacer(),
          ShimmerBlock(width: 120, height: 36, borderRadius: BorderRadius.all(Radius.circular(8))),
        ],
      ),
    );
  }

  Widget _cards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: List.generate(cardCount, (i) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 200,
              height: 120,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  ShimmerBlock(width: 120, height: 18),
                  SizedBox(height: 10),
                  ShimmerBlock(width: double.infinity, height: 26),
                  SizedBox(height: 8),
                  ShimmerBlock(width: 90, height: 12),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _mainPanel(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // top controls
              Row(children: const [
                ShimmerBlock(width: 180, height: 46),
                Spacer(),
                ShimmerBlock(width: 120, height: 40),
              ]),
              SizedBox(height: 12),
              // graph placeholder
              const SizedBox(height: 8),
              const ShimmerBlock(width: double.infinity, height: 260, borderRadius: BorderRadius.all(Radius.circular(12))),
              SizedBox(height: 12),
              // below cards
              Row(
                children: const [
                  Expanded(child: ShimmerBlock(width: double.infinity, height: 80)),
                  SizedBox(width: 12),
                  Expanded(child: ShimmerBlock(width: double.infinity, height: 80)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: Column(
          children: [
            _header(),
            const SizedBox(height: 10),
            _cards(),
            const SizedBox(height: 18),
            _mainPanel(context),
          ],
        ),
      ),
    );
  }
}