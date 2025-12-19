// lib/src/ui/staff_card.dart
import 'package:flutter/material.dart';
import '../models/staff_model.dart';

class StaffCardWidget extends StatelessWidget {
  final StaffModel staff;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const StaffCardWidget({super.key, required this.staff, this.onDelete, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final status = (staff.status ?? 'active').toLowerCase();
    Color statusColor = Colors.green;
    String statusText = status[0].toUpperCase() + status.substring(1);
    if (status == 'inactive') {
      statusColor = Colors.redAccent;
    } else if (status == 'safe' || status == 'staffe' || status == 'stalve') {
      statusColor = Colors.green.shade700;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            CircleAvatar(radius: 28, backgroundImage: staff.avatar != null ? NetworkImage(staff.avatar!) : null, child: staff.avatar == null ? Text(staff.name.isNotEmpty ? staff.name[0] : '') : null),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 4),
                Text(staff.role ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 6),
                Row(children: [
                  Text(staff.email ?? '', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  const SizedBox(width: 8),
                  Text(staff.phone ?? '', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ]),
              ]),
            ),
            const SizedBox(width: 12),
            Column(children: [
              Container(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(status == 'active' ? Icons.check_circle : Icons.remove_circle, color: statusColor, size: 18), const SizedBox(width: 6), Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold))])),
              const SizedBox(height: 8),
              Row(children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: onEdit),
                IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: onDelete),
              ]),
            ])
          ]),
        ),
      ),
    );
  }
}