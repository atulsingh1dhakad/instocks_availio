import 'package:flutter/material.dart';
import '../reusable/shimmer_loading.dart';

class AddProductSkeleton extends StatelessWidget {
  const AddProductSkeleton({Key? key}) : super(key: key);

  Widget _rowBlock() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: ShimmerBlock(width: double.infinity, height: 36),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(children: const [
                ShimmerBlock(width: 60, height: 60),
                SizedBox(width: 12),
                Expanded(child: ShimmerBlock(width: double.infinity, height: 36)),
              ]),
              const SizedBox(height: 12),
              _rowBlock(),
              _rowBlock(),
              _rowBlock(),
              _rowBlock(),
              const SizedBox(height: 12),
              const ShimmerBlock(width: double.infinity, height: 160),
            ],
          ),
        ),
      ),
    );
  }
}