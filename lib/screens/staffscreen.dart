import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  static const String apiToken = '0ff738d516ce887efe7274d43acd8043';
  static const String WEB_API_URL = "https://cors-anywhere.herokuapp.com/https://avalio-api.onrender.com/";
  static const String APP_API_URL = "https://avalio-api.onrender.com/";
  String get apiUrl => kIsWeb ? WEB_API_URL : APP_API_URL;

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
      final url = Uri.parse('${apiUrl}store/store-employee-details');
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text("Staff Management", style: TextStyle(color: Colors.black)),
          actions: [
            const Icon(Icons.notifications, color: Colors.black),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircleAvatar(child: Icon(Icons.person, color: Colors.black)),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: "Staff Management"),
              Tab(text: "Attendance"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StaffTable(
              staffList: staffList,
              isLoading: isLoading,
              errorMessage: errorMessage,
              onRefresh: fetchStaff,
            ),
            const Center(
              child: Text(
                "Attendance Tab Content",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // implement add staff
          },
          label: const Text("Add Staff", style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.add, color: Colors.white),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }
}

class StaffTable extends StatelessWidget {
  final List<Map<String, dynamic>> staffList;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;
  const StaffTable({
    Key? key,
    required this.staffList,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
  }) : super(key: key);

  Widget _metricBox(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 10),
          ),
          Text(
            value == null ? "" : value.toString(),
            style: const TextStyle(color: Colors.black87, fontSize: 10),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (staffList.isEmpty) {
      return const Center(child: Text('No staff found.', style: TextStyle(color: Colors.black)));
    }
    return ListView.builder(
      itemCount: staffList.length,
      itemBuilder: (context, index) {
        final staff = staffList[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            shadowColor: Colors.black26,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage("https://via.placeholder.com/50"),
                      radius: 25,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff["name"] ?? "",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            staff["user_type"] ?? "",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              _metricBox("Email", staff["email"]),
                              _metricBox("Phone", staff["phone"]),
                              _metricBox("ID", staff["user_id"]),
                              _metricBox("Store", staff["store_id"]),
                              _metricBox("Branch", staff["branch"]),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Created at: ${staff["created_at"] ?? ""}",
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.pinkAccent),
                          tooltip: "View Staff",
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: "Edit Staff",
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: "Delete Staff",
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}