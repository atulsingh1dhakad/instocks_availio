import 'package:flutter/material.dart';

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Center(
        child: Text(
          'Add Product Screen',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}