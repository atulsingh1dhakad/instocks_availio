// lib/src/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_event.dart';
import '../blocs/user/user_state.dart';
import '../repositories/user_repository.dart';
import '../services/user_service.dart';
import '../ui/profile_shimmer.dart';
import '../ui/profile_header.dart';
import '../../consts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserBloc _userBloc;

  @override
  void initState() {
    super.initState();
    final svc = UserService(apiUrl: API_URL, apiToken: API_TOKEN);
    final repo = UserRepository(service: svc);
    _userBloc = UserBloc(repository: repo);
    _userBloc.add(LoadUserProfile());
  }

  @override
  void dispose() {
    _userBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserBloc>.value(
      value: _userBloc,
      child: Scaffold(
        backgroundColor: const Color(0xfff8fafd),
        body: SafeArea(
          child: BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              if (state is UserLoadInProgress || state is UserInitial) {
                return const ProfileShimmer();
              } else if (state is UserLoadFailure) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(state.message, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: () => _userBloc.add(LoadUserProfile()), child: const Text('Retry')),
                  ]),
                );
              } else if (state is UserLoadSuccess) {
                final profile = state.profile;
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      ProfileHeader(profile: profile),
                      const SizedBox(height: 16),
                      Container(
                        color: Colors.white,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        child: Text("Admin of ${profile.storeId}. Contact at ${profile.email} or ${profile.phone}.",
                            style: const TextStyle(fontSize: 16, color: Color(0xff494949))),
                      ),
                      const SizedBox(height: 16),
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
                            _buildStat(Icons.verified_user, profile.type, "Specializes in", const Color(0xff9b6ef3)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // PROFILE AREAS
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        width: double.infinity,
                        color: Colors.white,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text("PROFILE AREAS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1, color: Color(0xff232323))),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 120, height: 120, child: _DonutChart(practiceAreas: [
                                {"label": "Management", "color": Colors.orange, "percent": 35},
                                {"label": "Inventory", "color": Colors.cyan, "percent": 35},
                                {"label": "Sales", "color": Colors.purple, "percent": 30},
                              ])),
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
                          Text("As an admin, manages store operations, inventory, and sales. Contact for support or management queries.",
                              style: TextStyle(color: Colors.grey[700], fontSize: 15)),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      Container(color: Colors.white, child: Row(children: [_buildTab("About", selected: true), _buildTab("Contact"), _buildTab("Review"), _buildTab("Cost")])),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              } else {
                return const Center(child: Text('Unexpected state'));
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label, Color color) {
    return Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 5), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 12, color: Color(0xff7b7b7b)))]);
  }

  Widget _buildAreaRow(String label, Color color, int percent) {
    return Padding(padding: const EdgeInsets.only(bottom: 10.0), child: Row(children: [Container(width: 16, height: 4, color: color), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 16, color: Color(0xff4a4a4a))), const Spacer(), Text("$percent%", style: const TextStyle(fontSize: 16, color: Color(0xff6f6f6f)))]));
  }

  Widget _buildTab(String label, {bool selected = false}) {
    return Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 18), alignment: Alignment.center, decoration: selected ? const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xff4e8af0), width: 3))) : null, child: Text(label, style: TextStyle(color: selected ? const Color(0xff4e8af0) : const Color(0xffa5a5a5), fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 16))));
  }
}

// Donut Chart for profile areas (kept local to screen file)
class _DonutChart extends StatelessWidget {
  final List<Map<String, dynamic>> practiceAreas;
  const _DonutChart({required this.practiceAreas});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DonutChartPainter(practiceAreas), child: Container());
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
      final paint = Paint()..color = area["color"]..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startRadian, sweepRadian, false, paint);
      startRadian += sweepRadian;
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}