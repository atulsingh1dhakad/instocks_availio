import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:instockavailio/consts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  List<Map<String, dynamic>> staffList = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';
  String selectedStatus = 'All';

  static const String apiToken = '0ff738d516ce887efe7274d43acd8043';

  @override
  void initState() {
    super.initState();
    fetchStaff();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final String accessToken = prefs.getString('access_token')?.trim() ?? '';
    // If token_type is stored, respect it (otherwise default to Bearer)
    final String tokenTypeRaw = prefs.getString('token_type') ?? 'Bearer';
    final String tokenType = tokenTypeRaw.trim().isEmpty ? 'Bearer' : tokenTypeRaw.trim();
    final String authorizationHeader = '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} $accessToken';

    return {
      'Content-Type': 'application/json',
      // include both formats in case backend expects one or the other
      'x-api-token': apiToken,
      'x_api_token': apiToken,
      'Authorization': authorizationHeader,
    };
  }

  Future<void> fetchStaff() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('${API_URL}store/store-employee-details');
      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        List<Map<String, dynamic>> items = [];
        if (data is List) {
          items = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] is List) {
          items = List<Map<String, dynamic>>.from(data['data']);
        }
        setState(() {
          staffList = items;
          isLoading = false;
        });
      } else {
        String body = resp.body;
        setState(() {
          errorMessage = "Failed to load staff: ${resp.statusCode} - $body";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredStaff {
    List<Map<String, dynamic>> filtered = staffList;
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((staff) {
        final query = searchQuery.toLowerCase();
        return (staff['name']?.toString().toLowerCase().contains(query) ?? false) ||
            (staff['role']?.toString().toLowerCase().contains(query) ?? false) ||
            (staff['user_id']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
    }
    switch (selectedStatus) {
      case 'Active':
        filtered = filtered.where((s) => s['status'] == 'active').toList();
        break;
      case 'Inactive':
        filtered = filtered.where((s) => s['status'] == 'inactive').toList();
        break;
      case 'Staffe':
        filtered = filtered.where((s) => s['status'] == 'staffe').toList();
        break;
      case 'Safe':
        filtered = filtered.where((s) => s['status'] == 'safe').toList();
        break;
      case 'Stiffe':
        filtered = filtered.where((s) => s['status'] == 'stiffe').toList();
        break;
      case 'All':
      default:
        break;
    }
    return filtered;
  }

  Future<void> _openAddStaffBottomSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: const AddStaffBottomSheet(),
        );
      },
    );

    if (added == true) {
      await fetchStaff();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Row(
          children: [
            // Main Staff Management Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Row(
                      children: [
                        const Icon(Icons.dashboard, color: Colors.black54),
                        const SizedBox(width: 10),
                        const Text("Staff Management",
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text("Add Staff"),
                          onPressed: _openAddStaffBottomSheet,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: "Search staff by name, Role, or ID",
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sorting Buttons
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          SortButton(
                            label: 'All',
                            selected: selectedStatus == 'All',
                            onTap: () => setState(() => selectedStatus = 'All'),
                          ),
                          SortButton(
                            label: 'Active',
                            selected: selectedStatus == 'Active',
                            onTap: () => setState(() => selectedStatus = 'Active'),
                          ),
                          SortButton(
                            label: 'Stalve',
                            selected: selectedStatus == 'Stalve',
                            onTap: () => setState(() => selectedStatus = 'Stalve'),
                          ),
                          SortButton(
                            label: 'Safe',
                            selected: selectedStatus == 'Safe',
                            onTap: () => setState(() => selectedStatus = 'Safe'),
                          ),
                          SortButton(
                            label: 'Inactive',
                            selected: selectedStatus == 'Inactive',
                            onTap: () => setState(() => selectedStatus = 'Inactive'),
                          ),
                          SortButton(
                            label: 'Stiffe',
                            selected: selectedStatus == 'Stiffe',
                            onTap: () => setState(() => selectedStatus = 'Stiffe'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Staff List Section
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : errorMessage != null
                          ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
                          : StaffList(staffs: filteredStaff),
                    ),
                  ],
                ),
              ),
            ),
            // Side Staff Info Section (Right)
            Container(
              width: 350,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                color: Colors.white,
                border: Border(left: BorderSide(color: Colors.grey.shade300, width: 1)),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 12, spreadRadius: 2),
                ],
              ),
              child: const ChatSection(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat Section Widget
class ChatSection extends StatelessWidget {
  const ChatSection({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ListTile(
          leading: CircleAvatar(child: Icon(Icons.chat)),
          title: Text("Team Chat", style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("Chat with team"),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              ChatBubble(message: "Welcome to staff management!", isMe: true),
              ChatBubble(message: "Please reach out if you need help.", isMe: false),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Send a message...",
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              suffixIcon: Icon(Icons.send),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  const ChatBubble({required this.message, required this.isMe, super.key});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(message, style: TextStyle(color: isMe ? Colors.blue : Colors.black)),
      ),
    );
  }
}

class SortButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const SortButton({required this.label, required this.selected, required this.onTap, super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.blueAccent : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? Colors.blue : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// Staff List UI
class StaffList extends StatelessWidget {
  final List<Map<String, dynamic>> staffs;
  const StaffList({required this.staffs, super.key});
  @override
  Widget build(BuildContext context) {
    if (staffs.isEmpty) {
      return const Center(child: Text('No staff found.', style: TextStyle(color: Colors.black)));
    }
    return ListView.separated(
      itemCount: staffs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final staff = staffs[idx];
        return StaffCard(staff: staff);
      },
    );
  }
}

class StaffCard extends StatelessWidget {
  final Map<String, dynamic> staff;
  const StaffCard({required this.staff, super.key});
  @override
  Widget build(BuildContext context) {
    // Status logic
    String statusText = "Active";
    Color statusColor = Colors.green;
    if (staff["status"] == "inactive") {
      statusText = "Inactive";
      statusColor = Colors.redAccent;
    } else if (staff["status"] == "safe") {
      statusText = "Safe";
      statusColor = Colors.green.shade700;
    } else if (staff["status"] == "staffe") {
      statusText = "Staffe";
      statusColor = Colors.green.shade400;
    } else if (staff["status"] == "stiffe") {
      statusText = "Stiffe";
      statusColor = Colors.redAccent.shade100;
    } else if (staff["status"] == "stalve") {
      statusText = "Stalve";
      statusColor = Colors.green.shade300;
    }
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(staff["avatar"] ?? "https://via.placeholder.com/50"),
              radius: 28,
              onBackgroundImageError: (exception, stackTrace) {},
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  staff["name"] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(staff["role"] ?? staff["user_type"] ?? "",
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(staff["email"] ?? "", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  const SizedBox(width: 8),
                  Text(staff["phone"] != null ? staff["phone"].toString() : "",
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ]),
              ]),
            ),
            const SizedBox(width: 16),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(statusText == "Active" ? Icons.check_circle : Icons.remove_circle, color: statusColor, size: 20),
                const SizedBox(width: 6),
                Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet widget that contains the Add Staff form and posts to /users/create-fresh-user
/// Behavior:
/// - store_id and branch are auto-filled from SharedPreferences and are read-only (not editable)
/// - user_id is ALWAYS generated from name + role (slugified) and shown read-only
/// - role is selected by toggling ChoiceChips (single selection)
/// - headers sent include x-api-token, x_api_token and Authorization (Bearer <token>) fetched from SharedPreferences
class AddStaffBottomSheet extends StatefulWidget {
  const AddStaffBottomSheet({super.key});

  @override
  State<AddStaffBottomSheet> createState() => _AddStaffBottomSheetState();
}

class _AddStaffBottomSheetState extends State<AddStaffBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _userIdCtrl = TextEditingController();
  final TextEditingController _storeIdCtrl = TextEditingController();
  final TextEditingController _branchCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _permissionsCtrl = TextEditingController();

  // Role selection (single)
  final List<String> availableRoles = [
    'manager',
    'cashier',
    'stock',
    'supervisor',
    'admin'
  ];
  String selectedRole = '';

  bool isSubmitting = false;
  static const String apiToken = '0ff738d516ce887efe7274d43acd8043';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserContext();
    _nameCtrl.addListener(_updateUserIdFromNameAndRole);
  }

  Future<void> _loadCurrentUserContext() async {
    final prefs = await SharedPreferences.getInstance();
    final storeId = prefs.getString('store_id') ??
        prefs.getString('storeId') ??
        prefs.getString('store') ??
        '';
    final branch = prefs.getString('branch') ?? prefs.getString('branch_id') ?? '';

    _storeIdCtrl.text = storeId;
    _branchCtrl.text = branch;

    final defaultUserType = prefs.getString('default_user_type') ?? '';
    if (defaultUserType.isNotEmpty && availableRoles.contains(defaultUserType.toLowerCase())) {
      selectedRole = defaultUserType.toLowerCase();
    }

    // Ensure user_id generated initially (if name/role already present)
    _updateUserIdFromNameAndRole();
  }

  void _updateUserIdFromNameAndRole() {
    final name = _nameCtrl.text.trim();
    final role = selectedRole.trim();

    String slugify(String input) {
      final lower = input.toLowerCase();
      final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      final collapsed = replaced.replaceAll(RegExp(r'_+'), '_');
      final trimmed = collapsed.trim().replaceAll(RegExp(r'^_+|_+$'), '');
      return trimmed.isEmpty ? '' : trimmed;
    }

    final namePart = slugify(name);
    final rolePart = slugify(role);

    String generated;
    if (namePart.isNotEmpty && rolePart.isNotEmpty) {
      generated = '${namePart}_$rolePart';
    } else if (namePart.isNotEmpty) {
      generated = namePart;
    } else if (rolePart.isNotEmpty) {
      generated = rolePart;
    } else {
      generated = '';
    }

    if (_userIdCtrl.text != generated) {
      _userIdCtrl.text = generated;
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final String accessToken = prefs.getString('access_token')?.trim() ?? '';
    final String tokenTypeRaw = prefs.getString('token_type') ?? 'Bearer';
    final String tokenType = tokenTypeRaw.trim().isEmpty ? 'Bearer' : tokenTypeRaw.trim();
    final String authorizationHeader = '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} $accessToken';

    return {
      'Content-Type': 'application/json',
      'x-api-token': apiToken,
      'x_api_token': apiToken,
      'Authorization': authorizationHeader,
    };
  }

  Future<void> _submit() async {
    // Validate role selection first
    if (selectedRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a role')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
    });

    final permissionsList = _permissionsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // phone: send as string if present (many APIs accept string phone)
    final phoneText = _phoneCtrl.text.trim();

    final payload = <String, dynamic>{
      "name": _nameCtrl.text.trim(),
      "user_type": selectedRole,
      "email": _emailCtrl.text.trim(),
      if (phoneText.isNotEmpty) "phone": phoneText,
      "user_id": _userIdCtrl.text.trim(),
      "store_id": _storeIdCtrl.text.trim(),
      "branch": _branchCtrl.text.trim(),
      "password": _passwordCtrl.text.trim(),
      "permissions": permissionsList,
    };

    try {
      final headers = await _getAuthHeaders();
      final url = Uri.parse('${API_URL}users/create-fresh-user');

      // Debug prints to help diagnose 400 responses
      debugPrint('--- CREATE STAFF REQUEST ---');
      debugPrint('URL: $url');
      debugPrint('HEADERS: ${jsonEncode(headers)}');
      debugPrint('BODY: ${jsonEncode(payload)}');

      final resp = await http.post(url, headers: headers, body: json.encode(payload));

      debugPrint('--- RESPONSE ---');
      debugPrint('STATUS: ${resp.statusCode}');
      debugPrint('BODY: ${resp.body}');

      String serverMessage = 'Failed to add staff: ${resp.statusCode}';
      try {
        final body = json.decode(resp.body);
        if (body is Map) {
          if (body['message'] != null) serverMessage = body['message'].toString();
          else if (body['errors'] != null) serverMessage = jsonEncode(body['errors']);
          else serverMessage = jsonEncode(body);
        } else {
          serverMessage = resp.body;
        }
      } catch (_) {
        serverMessage = resp.body;
      }

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff added successfully')));
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serverMessage)));
      }
    } catch (e) {
      debugPrint('HTTP ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_updateUserIdFromNameAndRole);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _userIdCtrl.dispose();
    _storeIdCtrl.dispose();
    _branchCtrl.dispose();
    _passwordCtrl.dispose();
    _permissionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with Material to get rounded white sheet look
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 4),
                const Text('Add Staff', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 12),
                // Role selection using ChoiceChips (single selection)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('Role', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: availableRoles.map((role) {
                    final display = role[0].toUpperCase() + role.substring(1);
                    final selected = selectedRole == role;
                    return ChoiceChip(
                      label: Text(display),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          selectedRole = v ? role : '';
                          _updateUserIdFromNameAndRole();
                        });
                      },
                      selectedColor: Colors.blueAccent,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // generated user id (read-only)
                TextFormField(
                  controller: _userIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'User ID (auto-generated)',
                    helperText: 'Generated from name and role, not editable',
                  ),
                  readOnly: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'User ID cannot be empty (fill name and role)';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter email';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                // store id (auto-filled, read-only)
                TextFormField(
                  controller: _storeIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Store ID',
                    helperText: 'Filled from current user and not editable',
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 8),
                // branch (auto-filled, read-only)
                TextFormField(
                  controller: _branchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Branch',
                    helperText: 'Filled from current user and not editable',
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v == null || v.trim().length < 6 ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _permissionsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Permissions (comma separated)',
                    hintText: 'e.g. read_products,create_orders',
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submit,
                      child: isSubmitting
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create Staff'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: isSubmitting ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
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