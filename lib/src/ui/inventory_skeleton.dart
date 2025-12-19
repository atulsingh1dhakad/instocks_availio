import 'package:flutter/material.dart';
import '../reusable/shimmer_loading.dart';

class InventorySkeleton extends StatelessWidget {
  final int itemCount;
  const InventorySkeleton({Key? key, this.itemCount = 8}) : super(key: key);


  Widget _listItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                const ShimmerBlock(width: 50, height: 50, borderRadius: BorderRadius.all(Radius.circular(6))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBlock(width: double.infinity, height: 16),
                      SizedBox(height: 6),
                      ShimmerBlock(width: 180, height: 12),
                      SizedBox(height: 10),
                      ShimmerBlock(width: 260, height: 12),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: const [
                    ShimmerBlock(width: 28, height: 28, borderRadius: BorderRadius.all(Radius.circular(8))),
                    SizedBox(height: 8),
                    ShimmerBlock(width: 28, height: 28, borderRadius: BorderRadius.all(Radius.circular(8))),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rightPanel() {
    return Container(
      width: 350,
      decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade200))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            ShimmerBlock(width: double.infinity, height: 46),
            SizedBox(height: 12),
            ShimmerBlock(width: double.infinity, height: 16),
            SizedBox(height: 12),
            ShimmerBlock(width: double.infinity, height: 120),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text("Inventory Management", style: TextStyle(color: Colors.black))),
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: ListView.builder(
                  itemCount: itemCount,
                  itemBuilder: (_, __) => _listItem(),
                ),
              ),
            ),
            _rightPanel(),
          ],
        ),
      ),
    );
  }
}