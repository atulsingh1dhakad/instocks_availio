// lib/src/screens/staff_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../consts.dart';
import '../blocs/staff/StaffBloc.dart';
import '../blocs/staff/StaffEvent.dart';
import '../blocs/staff/StaffState.dart';
import '../repositories/staff_repository.dart';
import '../services/staff_service.dart';
import '../ui/staff_shimmer.dart';
import '../ui/staff_card.dart';
import '../ui/add_staff_sheet.dart';
import '../models/staff_model.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  late StaffBloc _bloc;
  String search = '';
  String filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    // Standardized service initialization using central ApiClient
    final svc = StaffService();
    final repo = StaffRepository(service: svc);
    _bloc = StaffBloc(repository: repo);
    _bloc.add(LoadStaff());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _openAddSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(value: _bloc, child: const AddStaffSheet()),
    );
    if (result == true) _bloc.add(LoadStaff());
  }

  List<StaffModel> _filter(List<StaffModel> list) {
    var filtered = list;
    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered.where((s) => s.name.toLowerCase().contains(q) || (s.role ?? '').toLowerCase().contains(q) || s.id.toLowerCase().contains(q)).toList();
    }
    if (filterStatus != 'All') {
      filtered = filtered.where((s) => (s.status ?? '').toLowerCase() == filterStatus.toLowerCase()).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffBloc>.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.dashboard, color: Colors.black54),
                        const SizedBox(width: 10),
                        const Text('Staff Management', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        ElevatedButton.icon(onPressed: _openAddSheet, icon: const Icon(Icons.add), label: const Text('Add Staff')),
                      ]),
                      const SizedBox(height: 24),
                      TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search staff by name, role, or id', border: OutlineInputBorder()), onChanged: (v) => setState(() => search = v)),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (final label in ['All', 'Active', 'Inactive', 'Safe', 'Stalve', 'Staffe'])
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(label: Text(label), selected: filterStatus == label, onSelected: (_) => setState(() => filterStatus = label)),
                            )
                        ]),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: BlocConsumer<StaffBloc, StaffState>(
                          listener: (context, state) {
                            if (state is StaffActionSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                            } else if (state is StaffActionFailure) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                            }
                          },
                          builder: (context, state) {
                            if (state is StaffLoadInProgress || state is StaffInitial) {
                              return const StaffShimmer();
                            } else if (state is StaffLoadFailure) {
                              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(state.message, style: const TextStyle(color: Colors.red)), const SizedBox(height: 8), ElevatedButton(onPressed: () => _bloc.add(LoadStaff()), child: const Text('Retry'))]));
                            } else if (state is StaffLoadSuccess) {
                              final staff = _filter(state.staff);
                              if (staff.isEmpty) return const Center(child: Text('No staff found.'));
                              return ListView.separated(itemCount: staff.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (context, idx) {
                                final s = staff[idx];
                                return StaffCardWidget(staff: s, onDelete: () => _confirmDelete(s), onEdit: () => _openEdit(s));
                              });
                            } else {
                              return const Center(child: Text('Unexpected state'));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 350, decoration: BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: Colors.grey.shade300))), child: const _RightPanel()),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(StaffModel s) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete Staff'), content: Text('Delete ${s.name}?'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete'))]));
    if (ok == true) {
      _bloc.add(DeleteStaff(s.id));
    }
  }

  void _openEdit(StaffModel s) {
    // For now reuse add sheet for create only — implement edit UI as needed.
    // Optionally pass initial data to AddStaffSheet to support editing.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit not implemented')));
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const ListTile(leading: CircleAvatar(child: Icon(Icons.chat)), title: Text('Team Chat', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('Chat with team')),
      const Divider(),
      const Expanded(child: _ChatList()),
      Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: InputDecoration(hintText: 'Send a message...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: const Icon(Icons.send)))),
    ]);
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: const [
      _ChatBubble(message: 'Welcome to staff management!', isMe: true),
      _ChatBubble(message: 'Please reach out if you need help.', isMe: false),
    ]);
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  const _ChatBubble({required this.message, required this.isMe, super.key});
  @override
  Widget build(BuildContext context) {
    return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: isMe ? Colors.blue[100] : Colors.grey[200], borderRadius: BorderRadius.circular(15)), child: Text(message, style: TextStyle(color: isMe ? Colors.blue : Colors.black))));
  }
}
