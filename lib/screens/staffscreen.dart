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
    final String? accessToken = prefs.getString('access_token');
    final String? tokenTypeRaw = prefs.getString('token_type');
    final String tokenType = (tokenTypeRaw ?? 'Bearer').trim();
    final String? useAccessToken =
    accessToken != null && accessToken.trim().isNotEmpty ? accessToken.trim() : null;
    final String authorizationHeader =
        '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} ${useAccessToken ?? ""}';

    return {
      'Content-Type': 'application/json',
      'x-api-token': apiToken,
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
        }
        setState(() {
          staffList = items;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load staff: ${resp.statusCode}";
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
        return (staff['name']?.toLowerCase().contains(query) ?? false) ||
            (staff['role']?.toLowerCase().contains(query) ?? false) ||
            (staff['user_id']?.toString().contains(query) ?? false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Row(
          children: [
            // Chat Section (Left)

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
                          onPressed: () {},
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
                        decoration: InputDecoration(
                          hintText: "Search staff by name, Role, or ID",
                          prefixIcon: const Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                          ? Center(
                          child: Text(errorMessage!,
                              style: const TextStyle(color: Colors.red)))
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
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ChatSection()),
          ],
        ),
      ),
    );
  }
}

/// Chat Section Widget
class ChatSection extends StatelessWidget {
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
            children: [
              ChatBubble(
                message: "Welcome to staff management!",
                isMe: true,
              ),
              ChatBubble(
                message: "Please reach out if you need help.",
                isMe: false,
              ),
              // Add more chat bubbles as needed
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
  const ChatBubble({required this.message, required this.isMe});
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
  const SortButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
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
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// Staff List UI
class StaffList extends StatelessWidget {
  final List<Map<String, dynamic>> staffs;
  const StaffList({required this.staffs});
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
  const StaffCard({required this.staff});
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff["name"] ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    staff["role"] ?? staff["user_type"] ?? "",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        staff["email"] ?? "",
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        staff["phone"] != null ? staff["phone"].toString() : "", // Fix: always use String
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    statusText == "Active"
                        ? Icons.check_circle
                        : Icons.remove_circle,
                    color: statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}