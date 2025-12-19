// lib/src/ui/add_staff_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/staff/StaffBloc.dart';
import '../blocs/staff/StaffEvent.dart';

class AddStaffSheet extends StatefulWidget {
  const AddStaffSheet({super.key});
  @override
  State<AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<AddStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _userId = TextEditingController();
  String _role = 'cashier';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(_generateUserId);
  }

  void _generateUserId() {
    final name = _name.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final role = _role.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    _userId.text = (name.isNotEmpty ? name : 'user') + '_' + role;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final payload = {
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'user_id': _userId.text.trim(),
      'user_type': _role,
      'password': _password.text.trim(),
      'permissions': [], // allow UI to accept comma separated if you want
    };
    // Dispatch to bloc
    context.read<StaffBloc>().add(AddStaff(payload));
    // wait for action result via listener in parent screen; close sheet
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _userId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 12),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 48, height: 4, margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Text('Create Staff', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(value: _role, items: ['manager', 'cashier', 'stock', 'supervisor', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setState(() { _role = v!; _generateUserId(); }), decoration: const InputDecoration(labelText: 'Role')),
                const SizedBox(height: 8),
                TextFormField(controller: _userId, decoration: const InputDecoration(labelText: 'User id (auto)'), readOnly: true),
                const SizedBox(height: 8),
                TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v == null || v.trim().isEmpty ? 'Enter email' : null),
                const SizedBox(height: 8),
                TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
                const SizedBox(height: 8),
                TextFormField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: (v) => v == null || v.trim().length < 6 ? 'Min 6 chars' : null),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: ElevatedButton(onPressed: _submitting ? null : _submit, child: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Create'))),
                  const SizedBox(width: 8),
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                ]),
                const SizedBox(height: 12),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}