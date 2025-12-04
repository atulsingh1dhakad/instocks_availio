import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:instockavailio/consts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UserProfile {
  final String name;
  final String type;
  final String email;
  final String phone;
  final String userId;
  final String storeId;

  UserProfile({
    required this.name,
    required this.type,
    required this.email,
    required this.phone,
    required this.userId,
    required this.storeId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] ?? '',
    type: json['type'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone']?.toString() ?? '',
    userId: json['user_id'] ?? '',
    storeId: json['store_id'] ?? '',
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<UserProfile?>? _profileFuture;

  // API KEY and URLs
  static const String apiToken = '0ff738d516ce887efe7274d43acd8043';

  @override
  void initState() {
    super.initState();
    _profileFuture = fetchUserProfile();
  }

  /// Save all profile info to SharedPreferences
  Future<void> saveProfileToPrefs(Map<String, dynamic> userJson) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in userJson.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is List) {
        // Save lists as JSON string
        await prefs.setString(key, jsonEncode(value));
      } else if (value == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value.toString());
      }
    }
  }

  Future<UserProfile?> fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('access_token');
    final String? tokenTypeRaw = prefs.getString('token_type');
    final String tokenType = (tokenTypeRaw ?? 'Bearer').trim();
    final String? useAccessToken =
    accessToken != null && accessToken.trim().isNotEmpty ? accessToken.trim() : null;
    final String authorizationHeader =
        '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} ${useAccessToken ?? ""}';

    final url = Uri.parse('${API_URL}users/me');

    debugPrint('==== PROFILE FETCH DEBUG ====');
    debugPrint('accessToken: $accessToken');
    debugPrint('tokenType: $tokenType');
    debugPrint('authorizationHeader: $authorizationHeader');
    debugPrint('x-api-token (constant): $apiToken');
    debugPrint('URL: $url');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-api-token': apiToken,
        'Authorization': authorizationHeader,
      },
    );

    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> userJson = json.decode(response.body);

        // Save all profile info into SharedPreferences
        await saveProfileToPrefs(userJson);

        return UserProfile.fromJson(userJson);
      } catch (e) {
        debugPrint("JSON decode error: $e");
        return null;
      }
    } else {
      return null;
    }
  }

  Widget _buildShimmerLine({double width = 120, double height = 20}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafd),
      body: SafeArea(
        child: FutureBuilder<UserProfile?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;

            if (snapshot.hasError) {
              return const Center(child: Text("Failed to load profile (error)."));
            }

            if (!loading && (!snapshot.hasData || snapshot.data == null)) {
              return const Center(child: Text("Failed to load profile."));
            }

            final user = snapshot.data;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar (no network image!)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            color: Colors.grey[200],
                            width: 96,
                            height: 96,
                            child: const Icon(Icons.person, size: 64, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Main Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              loading
                                  ? _buildShimmerLine(width: 200, height: 32)
                                  : Text(
                                user!.name,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff212121),
                                ),
                              ),
                              const SizedBox(height: 8),
                              loading
                                  ? Row(
                                children: [
                                  _buildShimmerLine(width: 80, height: 28),
                                  const SizedBox(width: 8),
                                  _buildShimmerLine(width: 80, height: 28),
                                ],
                              )
                                  : Wrap(
                                spacing: 8,
                                children: [
                                  Chip(
                                    label: Text(
                                      user!.type.toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                    backgroundColor: const Color(0xff66d47e),
                                  ),
                                  Chip(
                                    label: Text(
                                      user.storeId,
                                      style: const TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                    backgroundColor: const Color(0xff40bfff),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              loading
                                  ? _buildShimmerLine(width: 220, height: 24)
                                  : Row(
                                children: [
                                  const Icon(Icons.email, size: 18, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    user!.email,
                                    style: const TextStyle(
                                        color: Color(0xff616161), fontSize: 15),
                                  ),
                                  const SizedBox(width: 18),
                                  const Icon(Icons.phone, size: 18, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    user.phone,
                                    style: const TextStyle(
                                        color: Color(0xff616161), fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              loading
                                  ? _buildShimmerLine(width: 120, height: 18)
                                  : Row(
                                children: [
                                  const Icon(Icons.badge, size: 18, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    "User ID: ${user!.userId}",
                                    style: const TextStyle(
                                        color: Color(0xff616161), fontSize: 15),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // About section
                  Container(
                    color: Colors.white,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    child: loading
                        ? _buildShimmerLine(width: 250, height: 16)
                        : Text(
                      "Admin of ${user!.storeId}. Contact at ${user.email} or ${user.phone}.",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff494949),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Analytics (static)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(Icons.percent, "100%", "Job Success", const Color(0xff4e8af0)),
                        _buildStat(Icons.attach_money, "\$100k+", "Total Earned", const Color(0xfffdbb4a)),
                        _buildStat(Icons.work_outline, "450", "Jobs", const Color(0xfffa6464)),
                        _buildStat(Icons.access_time, "4500", "Hours Worked", const Color(0xff71e0a9)),
                        _buildStat(Icons.verified_user, user?.type ?? '', "Specializes in", const Color(0xff9b6ef3)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Profile Areas
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    width: double.infinity,
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PROFILE AREAS",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 1,
                            color: Color(0xff232323),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: _DonutChart(practiceAreas: [
                                {"label": "Management", "color": Colors.orange, "percent": 35},
                                {"label": "Inventory", "color": Colors.cyan, "percent": 35},
                                {"label": "Sales", "color": Colors.purple, "percent": 30},
                              ]),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildAreaRow("Management", Colors.orange, 35),
                                  _buildAreaRow("Inventory", Colors.cyan, 35),
                                  _buildAreaRow("Sales", Colors.purple, 30),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          "As an admin, manages store operations, inventory, and sales. Contact for support or management queries.",
                          style: TextStyle(color: Colors.grey[700], fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bottom navigation
                  Container(
                    color: Colors.white,
                    child: Row(
                      children: [
                        _buildTab("About", selected: true),
                        _buildTab("Contact"),
                        _buildTab("Review"),
                        _buildTab("Cost"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xff7b7b7b))),
      ],
    );
  }

  Widget _buildAreaRow(String label, Color color, int percent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 4,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Color(0xff4a4a4a)),
          ),
          const Spacer(),
          Text(
            "$percent%",
            style: const TextStyle(fontSize: 16, color: Color(0xff6f6f6f)),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, {bool selected = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: selected
            ? const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xff4e8af0),
              width: 3,
            ),
          ),
        )
            : null,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xff4e8af0) : const Color(0xffa5a5a5),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// Donut Chart for profile areas
class _DonutChart extends StatelessWidget {
  final List<Map<String, dynamic>> practiceAreas;

  const _DonutChart({required this.practiceAreas});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutChartPainter(practiceAreas),
      child: Container(),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> practiceAreas;

  _DonutChartPainter(this.practiceAreas);

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 22;
    final double radius = (size.width / 2) - strokeWidth / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    double startRadian = -90 * 3.1415927 / 180;
    for (final area in practiceAreas) {
      final sweepRadian = (area["percent"] / 100.0) * 2 * 3.1415927;
      final paint = Paint()
        ..color = area["color"]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startRadian,
        sweepRadian,
        false,
        paint,
      );
      startRadian += sweepRadian;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}