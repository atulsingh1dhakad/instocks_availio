// lib/src/screens/dashboard_screen.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:instockavailio/src/blocs/dashboard/DashboardBloc.dart';
import 'package:instockavailio/src/blocs/dashboard/DashboardEvent.dart';
import 'package:instockavailio/src/blocs/dashboard/DashboardState.dart';
import 'package:instockavailio/src/models/dashboardModels.dart';
import 'package:instockavailio/src/helpers/formatters.dart';
import 'package:instockavailio/src/ui/dashboard_skeleton.dart';

// NEW imports for auth handling on 401
import 'package:instockavailio/src/blocs/auth/auth_bloc.dart';
import 'package:instockavailio/src/blocs/auth/auth_event.dart' show LoggedOut;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  String _selectedPeriod = "Daily";
  final List<String> _periods = ["Daily", "Weekly", "Monthly", "Yearly", "Overall"];

  AnimationController? _graphAnimController;
  int? _selectedPointIndex;
  Offset? _selectedPointLocal;
  String? _selectedPointLabel;

  @override
  void initState() {
    super.initState();
    _graphAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    // request data after first frame so repository/context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardBloc>().add(DashboardRequested(period: _selectedPeriod));
    });
  }

  @override
  void dispose() {
    _graphAnimController?.dispose();
    super.dispose();
  }

  void _onPeriodChanged(String p) {
    setState(() {
      _selectedPeriod = p;
      _selectedPointIndex = null;
      _selectedPointLocal = null;
    });
    context.read<DashboardBloc>().add(DashboardRequested(period: p));
    _graphAnimController?.forward(from: 0.0);
  }

  // Graph tap handling (uses SalesPoint model from models/dashboardModels.dart)
  void _handleGraphTap(Offset local, List<Offset> graphPoints, List<SalesPoint> points) {
    if (graphPoints.isEmpty || points.isEmpty) {
      setState(() {
        _selectedPointIndex = null;
        _selectedPointLocal = null;
        _selectedPointLabel = null;
      });
      return;
    }
    const double threshold = 24.0;
    int? nearestIdx;
    double nearestDist = double.infinity;
    for (int i = 0; i < graphPoints.length; i++) {
      final d = (graphPoints[i] - local).distance;
      if (d < nearestDist) {
        nearestDist = d;
        nearestIdx = i;
      }
    }
    if (nearestIdx != null && nearestDist <= threshold) {
      final idx = nearestIdx;
      setState(() {
        _selectedPointIndex = idx;
        _selectedPointLocal = graphPoints[idx];
        final String label = points[idx].xLabel;
        String short = label;
        try {
          if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(label)) {
            final dt = DateTime.parse(label);
            short = DateFormat('dd MMM').format(dt);
          } else if (RegExp(r'^\d{2}:\d{2}$').hasMatch(label)) {
            short = label;
          } else if (label.length > 12) {
            short = label.substring(0, 12) + '...';
          }
        } catch (_) {}
        _selectedPointLabel = short;
      });
    } else {
      setState(() {
        _selectedPointIndex = null;
        _selectedPointLocal = null;
        _selectedPointLabel = null;
      });
    }
  }

  Widget _buildDashboard(BuildContext context, DashboardLoadSuccess s) {
    final avatar = const CircleAvatar(radius: 24, backgroundImage: AssetImage("assets/images/avatar.png"));
    final totalSales = s.dataPoints.fold(0.0, (p, e) => p + e.value);
    final overview = _computeOverview(s.dataPoints);

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(Icons.search, color: Colors.grey, size: 22),
                          const SizedBox(width: 6),
                          const Text("Dashboard", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text("Rewas L. Dean", style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                          const SizedBox(width: 10),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          const SizedBox(width: 5),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  avatar,
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFF23262D), borderRadius: BorderRadius.circular(20)),
                    child: const Text("Oh Bsgo Voeh nw", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _dashboardCard(title: "Today's sales", value: Formatters.currencyINR(s.todaysSales), icon: Icons.bar_chart, color: const Color(0xFF208AFF)),
                  const SizedBox(width: 12),
                  _dashboardCard(title: "Pending Orders", value: s.pendingOrdersCount.toString(), icon: Icons.shopping_cart_outlined, color: const Color(0xFFFFB020)),
                  const SizedBox(width: 12),
                  _dashboardCard(title: "Low stock", value: "12 items", icon: Icons.inventory_2_outlined, color: const Color(0xFF6DD9A6)),
                  const SizedBox(width: 12),
                  _dashboardCard(title: "Earnings", value: "\$5,800", icon: Icons.account_balance_wallet_outlined, color: const Color(0xFF208AFF)),
                ]),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 2))]),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[400]!, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10, offset: Offset(0, 4))]),
                        child: SizedBox(
                          width: 180,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPeriod,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black),
                              dropdownColor: Colors.white,
                              items: _periods.map((String period) {
                                return DropdownMenuItem<String>(value: period, child: Text(period));
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) _onPeriodChanged(newValue);
                              },
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 280,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40, left: 8, right: 8),
                        child: AnimatedBuilder(
                          animation: _graphAnimController!,
                          builder: (context, child) {
                            return _salesGraph(s.dataPoints, _graphAnimController!.value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Total Sales', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 6),
                            Text(Formatters.currencyINR(totalSales), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]),
                          child: Row(children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: overview['color'] as Color, shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(overview['label'] as String, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: overview['color'] as Color))),
                            IconButton(onPressed: () {
                              final snack = '${overview['label']} — total ${Formatters.currencyINR(totalSales)}';
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snack)));
                            }, icon: Icon(Icons.info_outline, color: Colors.grey.shade600)),
                          ]),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 18),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _computeOverview(List<SalesPoint> pts) {
    if (pts.isEmpty) return {'label': 'No data', 'color': Colors.grey};
    if (pts.length == 1) {
      final v = pts.first.value;
      if (v <= 0) return {'label': 'No data', 'color': Colors.grey};
      return {'label': 'Stable', 'color': Colors.green};
    }
    final double first = pts.first.value;
    final double last = pts.last.value;
    if (first == 0) {
      if (last == 0) return {'label': 'Stable', 'color': Colors.grey};
      return {'label': 'Increasing', 'color': Colors.green};
    }
    final double pct = ((last - first) / first) * 100.0;
    if (pct >= 20) return {'label': 'Increasing', 'color': Colors.green};
    if (pct >= 5) return {'label': 'Good', 'color': Colors.lightGreen};
    if (pct > -5) return {'label': 'Stable', 'color': Colors.blueGrey};
    if (pct > -20) return {'label': 'Need attention', 'color': Colors.orange};
    return {'label': 'Terrible', 'color': Colors.red};
  }

  Widget _dashboardCard({required String title, required String value, required IconData icon, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Container(
        width: 200,
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))]),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(icon, color: color, size: 21), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500))]),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 2),
            Text("", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  Widget _salesGraph(List<SalesPoint> points, double animValue) {
    if (points.isEmpty) return Center(child: Text("No sales data for selected period.", style: TextStyle(color: Colors.grey)));

    final double yLabelWidth = 70;
    final double leftMargin = yLabelWidth + 12;
    final double rightMargin = 20;
    final double bottomMargin = 10;
    final double topMargin = 18;

    return LayoutBuilder(builder: (context, constraints) {
      final Size size = Size(constraints.maxWidth, constraints.maxHeight);
      final double graphWidth = size.width - leftMargin - rightMargin;
      final double pad = points.length > 1 ? (graphWidth / (points.length - 1)) : 0;
      final double maxY = points.map((e) => e.value).fold(0.0, (prev, val) => val > prev ? val : prev);

      final List<Offset> graphPoints = [];
      for (int i = 0; i < points.length; i++) {
        final double x = leftMargin + pad * i;
        final double graphHeight = size.height - topMargin - bottomMargin;
        final double y = topMargin + graphHeight - ((points[i].value / (maxY == 0 ? 1 : maxY)) * graphHeight);
        graphPoints.add(Offset(x, y));
      }

      return Stack(children: [
        CustomPaint(
          size: size,
          painter: SalesGraphPainter(points, animValue, maxY, pad, leftMargin, topMargin, bottomMargin, rightMargin),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) => _handleGraphTap(details.localPosition, graphPoints, points),
            onPanDown: (details) => _handleGraphTap(details.localPosition, graphPoints, points),
            onPanUpdate: (details) => _handleGraphTap(details.localPosition, graphPoints, points),
            onTap: () {
              if (_selectedPointIndex == null) {
                setState(() {
                  _selectedPointLocal = null;
                  _selectedPointLabel = null;
                });
              }
            },
          ),
        ),
        if (_selectedPointIndex != null && _selectedPointLocal != null)
          Positioned(
            left: (_selectedPointLocal!.dx - 60).clamp(0.0, size.width - 120),
            top: (_selectedPointLocal!.dy - 48).clamp(0.0, size.height - 40),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 120,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_selectedPointLabel ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(Formatters.currencyINR(points[_selectedPointIndex!].value), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
              ),
            ),
          ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(builder: (context, state) {
      if (state is DashboardLoadInProgress || state is DashboardInitial) {
        return const DashboardSkeleton();
      } else if (state is DashboardLoadFailure) {
        // If failure contains 401 / invalid token error, dispatch logout
        final msg = state.message?.toString() ?? '';
        final lower = msg.toLowerCase();
        final isAuthError = msg.contains('401') || lower.contains('invalid or expired token') || lower.contains('token expired') || lower.contains('unauthorized');
        if (isAuthError) {
          // perform logout via AuthBloc and inform user
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              context.read<AuthBloc>().add(LoggedOut());
            } catch (_) {}
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session expired. Please login again.')));
          });
          // show interim UI while RootPage / AuthBloc handles navigation
          return SafeArea(child: Scaffold(body: Center(child: Text('Session expired. Redirecting to login...', style: TextStyle(color: Colors.grey)))));
        }

        return SafeArea(child: Scaffold(body: Center(child: Text(state.message, style: const TextStyle(color: Colors.red)))));
      } else if (state is DashboardLoadSuccess) {
        _graphAnimController?.forward(from: 0.0);
        return _buildDashboard(context, state);
      }
      return const SizedBox.shrink();
    });
  }
}

/// SalesGraphPainter uses the SalesPoint model imported above (no duplicate model here).
class SalesGraphPainter extends CustomPainter {
  final List<SalesPoint> points;
  final double animValue;
  final double maxY;
  final double pad;
  final double leftMargin;
  final double topMargin;
  final double bottomMargin;
  final double rightMargin;

  SalesGraphPainter(this.points, this.animValue, this.maxY, this.pad,
      this.leftMargin, this.topMargin, this.bottomMargin, this.rightMargin);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final double graphWidth = size.width - leftMargin - rightMargin;
    final double graphHeight = size.height - topMargin - bottomMargin;

    final List<Offset> graphPoints = [];
    for (int i = 0; i < points.length; i++) {
      final double x = leftMargin + pad * i;
      final double y = topMargin + graphHeight -
          ((points[i].value / (maxY == 0 ? 1 : maxY)) * graphHeight) *
              animValue;
      graphPoints.add(Offset(x, y));
    }

    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    int nGrid = 6;
    for (int i = 0; i < nGrid; i++) {
      double y = topMargin + graphHeight - (i / (nGrid - 1)) * graphHeight;
      canvas.drawLine(
          Offset(leftMargin, y), Offset(size.width - rightMargin, y),
          gridPaint);
    }

    final Path fillPath = Path();
    if (graphPoints.isNotEmpty) {
      fillPath.moveTo(graphPoints[0].dx, graphPoints[0].dy);
      for (int i = 0; i < graphPoints.length - 1; i++) {
        final p1 = graphPoints[i];
        final p2 = graphPoints[i + 1];
        final controlX = (p1.dx + p2.dx) / 2;
        fillPath.quadraticBezierTo(controlX, p1.dy, p2.dx, p2.dy);
      }
      fillPath.lineTo(graphPoints.last.dx, topMargin + graphHeight);
      fillPath.lineTo(graphPoints.first.dx, topMargin + graphHeight);
      fillPath.close();
    }

    final Rect areaRect = Rect.fromLTRB(
        leftMargin, topMargin, size.width - rightMargin,
        topMargin + graphHeight);
    final Gradient areaGradient = LinearGradient(begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.blue.withOpacity(0.12), Colors.blue.withOpacity(0.03)]);
    final Paint fillPaint = Paint()
      ..shader = areaGradient.createShader(areaRect);
    canvas.drawPath(fillPath, fillPaint);

    final Path strokePath = Path();
    if (graphPoints.isNotEmpty) {
      strokePath.moveTo(graphPoints[0].dx, graphPoints[0].dy);
      for (int i = 0; i < graphPoints.length - 1; i++) {
        final p1 = graphPoints[i];
        final p2 = graphPoints[i + 1];
        final controlX = (p1.dx + p2.dx) / 2;
        strokePath.quadraticBezierTo(controlX, p1.dy, p2.dx, p2.dy);
      }
    }

    final Paint strokePaint = Paint()
      ..color = Colors.blue.shade800
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    canvas.drawPath(strokePath, strokePaint);

    final Paint dotPaint = Paint()
      ..color = Colors.white;
    final Paint dotEdge = Paint()
      ..color = Colors.blue.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (int i = 0; i < graphPoints.length; i++) {
      final p = graphPoints[i];
      canvas.drawCircle(p, 5.5, dotPaint);
      canvas.drawCircle(p, 5.5, dotEdge);
    }

    final TextStyle yAxisStyle = TextStyle(
        color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.w500);
    int nGridLabels = 6;
    for (int j = 0; j < nGridLabels; j++) {
      double y = topMargin + graphHeight -
          ((j / (nGridLabels - 1)) * graphHeight);
      double val = (maxY / (nGridLabels - 1)) * j;
      final tp = TextPainter(
          text: TextSpan(text: "₹${val.toStringAsFixed(0)}", style: yAxisStyle),
          textDirection: ui.TextDirection.ltr)
        ..layout(minWidth: 0, maxWidth: leftMargin - 8);
      tp.paint(canvas, Offset(leftMargin - tp.width - 8, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant SalesGraphPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.animValue != animValue ||
        oldDelegate.maxY != maxY || oldDelegate.pad != pad;
  }
}