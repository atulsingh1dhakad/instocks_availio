// lib/src/ui/cart_panel.dart
import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartPanel extends StatelessWidget {
  final List<CartItem> cart;
  final double subtotal;
  final double tax;
  final double total;
  final String customerName;
  final String customerPhone;
  final Function(String) onCustomerNameChanged;
  final Function(String) onCustomerPhoneChanged;
  final VoidCallback onClearCart;
  final Function(dynamic) onIncrease;
  final Function(dynamic) onDecrease;
  final Function() onProceed;
  final String paymentMode;
  final Function(String) onPaymentModeChanged;
  final bool isProceeding;

  const CartPanel({
    super.key,
    required this.cart,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.customerName,
    required this.customerPhone,
    required this.onCustomerNameChanged,
    required this.onCustomerPhoneChanged,
    required this.onClearCart,
    required this.onIncrease,
    required this.onDecrease,
    required this.onProceed,
    required this.paymentMode,
    required this.onPaymentModeChanged,
    required this.isProceeding,
  });

  Widget _billRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ]),
    );
  }

  Widget _paymentModes() {
    final modes = ["cash", "UPI", "card"];
    return Row(
      children: modes.map((mode) {
        final selected = paymentMode == mode;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () => onPaymentModeChanged(mode),
              style: ElevatedButton.styleFrom(backgroundColor: selected ? Colors.blue : Colors.grey[300]),
              child: Text(mode.toUpperCase(), style: TextStyle(color: selected ? Colors.white : Colors.black)),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            color: Colors.green[500],
            height: 52,
            child: Row(children: [
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: cart.isNotEmpty ? onClearCart : null,
                icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                label: const Text('Delete', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12)),
              ),
              const Spacer(),
            ]),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(customerName.isEmpty ? 'Billing for: ______' : 'Billing for: $customerName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          if (customerPhone.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('Phone: $customerPhone', style: const TextStyle(color: Colors.grey))),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, idx) {
                final item = cart[idx];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(radius: 14, child: Text('${item.qty}')),
                  title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  subtitle: Text('ID: ${item.product.id}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(item.priceUsed.toStringAsFixed(2)),
                    IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: () => onDecrease(item.product.id)),
                    IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => onIncrease(item.product.id)),
                  ]),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(children: [
              _billRow("Subtotal", subtotal.toStringAsFixed(2)),
              _billRow("Tax", tax.toStringAsFixed(2)),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), Text(total.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))]),
              const SizedBox(height: 8),
              _paymentModes(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cart.isNotEmpty && paymentMode.isNotEmpty && !isProceeding ? onProceed : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: isProceeding ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : Text(paymentMode.isEmpty ? 'Select Payment Mode' : 'Proceed', style: const TextStyle(color: Colors.white)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}