import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InvoicesTableScreen extends StatelessWidget {
  final List<Map<String, dynamic>> invoices;
  const InvoicesTableScreen({Key? key, required this.invoices}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Invoices Table")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              columns: [
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Invoice ID', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: invoices.map((row) {
                String dateStr = row['date'];
                String dateShow = "";
                try {
                  dateShow = DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr));
                } catch (_) {
                  dateShow = dateStr;
                }
                return DataRow(cells: [
                  DataCell(Text(dateShow)),
                  DataCell(Text("₹${(row['total'] as num).toStringAsFixed(2)}")),
                  DataCell(Text(row['invoice_id'].toString())),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}