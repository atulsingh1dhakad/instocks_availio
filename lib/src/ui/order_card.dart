// lib/src/ui/order_card.dart
import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isPending;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const OrderCard({
    super.key,
    required this.item,
    required this.isPending,
    this.onAccept,
    this.onReject,
  });

  Widget _statusButton(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = item['label']?.toString() ?? '';
    final leftStatus = item['leftStatus']?.toString() ?? '';
    final middle = item['middle']?.toString() ?? '';
    final rightStatus = item['rightStatus']?.toString() ?? '';
    final orderId = item['order_id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500))),
          const SizedBox(width: 10),
          _statusButton(leftStatus, Colors.red.shade100, Colors.red),
          const SizedBox(width: 10),
          Expanded(flex: 1, child: Text(middle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700))),
          const SizedBox(width: 10),
          _statusButton(rightStatus, Colors.blue.shade100, const Color(0xFF6C8AE3)),
          const SizedBox(width: 10),
          if (isPending) ...[
            ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF49A97C), minimumSize: const Size(60, 36)),
              child: const Text('Accept'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onReject,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(60, 36)),
              child: const Text('Reject'),
            ),
          ]
        ],
      ),
    );
  }
}