import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:instockavailio/consts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  String _selectedPeriod = "Daily";
  final List<String> _periods = [
    "Daily",
    "Weekly",
    "Monthly",
    "Yearly",
    "Overall",
  ];

  double? todaysSales;
  int? pendingOrdersCount;
  bool _loading = true;
  String? _errorMsg;

  String? _storeId;
  String? _branch;
  List<Map<String, dynamic>> invoices = [];
  List<SalesPoint> dataPoints = [];
  AnimationController? _graphAnimController;

  // For interactive tooltip
  int? _selectedPointIndex;
  Offset? _selectedPointLocal; // in graph local coords
  String? _selectedPointLabel;

  final NumberFormat _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _graphAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _initAndFetch();
  }

  @override
  void dispose() {
    _graphAnimController?.dispose();
    super.dispose();
  }

  Future<void> _initAndFetch() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? accessToken = prefs.getString('access_token');
      final String? tokenTypeRaw = prefs.getString('token_type');
      final String tokenType = (tokenTypeRaw ?? 'Bearer').trim();
      final String? useAccessToken = accessToken != null && accessToken.trim().isNotEmpty ? accessToken.trim() : null;
      final String authorizationHeader =
          '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} ${useAccessToken ?? ""}';

      final String apiToken = '0ff738d516ce887efe7274d43acd8043';

      // USER INFO
      final userResp = await http.get(
        Uri.parse('${API_URL}users/me'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-token': apiToken,
          'Authorization': authorizationHeader,
        },
      );
      if (userResp.statusCode != 200) {
        print("User API Error (${userResp.statusCode}):\n${userResp.body}");
        setState(() {
          _errorMsg = "User API Error (${userResp.statusCode}):\n${userResp.body}";
          _loading = false;
        });
        return;
      }
      final userJson = json.decode(userResp.body);
      _storeId = userJson['store_id'];
      _branch = userJson['branch'];

      if (_storeId == null || _branch == null) {
        print("User's store_id or branch missing.");
        setState(() {
          _errorMsg = "User's store_id or branch missing.";
          _loading = false;
        });
        return;
      }

      // TODAY'S SALES
      final salesResp = await http.get(
        Uri.parse('${API_URL}invoices/todays-salesamount-value'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-token': apiToken,
          'Authorization': authorizationHeader,
        },
      );
      double? sales = 0.0;
      if (salesResp.statusCode == 200) {
        final sJson = json.decode(salesResp.body);
        sales = (sJson is Map && sJson['total_sales'] != null)
            ? (sJson['total_sales'] as num).toDouble()
            : (sJson['sales'] ?? 0.0).toDouble();
      } else {
        print("Today's sales API Error (${salesResp.statusCode}):\n${salesResp.body}");
        setState(() {
          _errorMsg = "Today's sales API Error (${salesResp.statusCode}):\n${salesResp.body}";
          _loading = false;
        });
        return;
      }

      // PENDING ORDERS
      final pendingOrdersResp = await http.post(
        Uri.parse('${API_URL}order/pending-orders-count'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-token': apiToken,
          'Authorization': authorizationHeader,
        },
        body: jsonEncode({"store_id": _storeId, "branch": _branch}),
      );
      int? ordersCount;
      if (pendingOrdersResp.statusCode == 200) {
        final pJson = json.decode(pendingOrdersResp.body);
        if (pJson is Map && pJson.containsKey('pending_orders_count')) {
          ordersCount = (pJson['pending_orders_count'] as num).toInt();
        } else if (pJson is Map && pJson.containsKey('pending_orders')) {
          ordersCount = (pJson['pending_orders'] as num).toInt();
        } else if (pJson is Map && pJson.containsKey('count')) {
          ordersCount = (pJson['count'] as num).toInt();
        } else if (pJson is Map && pJson.containsKey('orders_count')) {
          ordersCount = (pJson['orders_count'] as num).toInt();
        } else {
          print("Pending orders API unknown response: ${pendingOrdersResp.body}");
          setState(() {
            _errorMsg = "Pending orders API unknown response: ${pendingOrdersResp.body}";
            _loading = false;
          });
          return;
        }
      } else {
        print("Pending orders API Error (${pendingOrdersResp.statusCode}):\n${pendingOrdersResp.body}");
        setState(() {
          _errorMsg = "Pending orders API Error (${pendingOrdersResp.statusCode}):\n${pendingOrdersResp.body}";
          _loading = false;
        });
        return;
      }

      // PAST YEAR INVOICES (GRAPH + TABLE)
      final invoicesResp = await http.get(
        Uri.parse('${API_URL}invoices/past-year-invoices?store_id=$_storeId&branch=$_branch'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-token': apiToken,
          'Authorization': authorizationHeader,
        },
      );
      print("invoices/past-year-invoices response:");
      print(invoicesResp.body);

      List<Map<String, dynamic>> invoiceData = [];
      if (invoicesResp.statusCode == 200) {
        final invJson = json.decode(invoicesResp.body);
        if (invJson is Map && invJson["invoices"] is List) {
          invoiceData = List<Map<String, dynamic>>.from(invJson["invoices"]);
        }
      }

      setState(() {
        todaysSales = sales;
        pendingOrdersCount = ordersCount;
        invoices = invoiceData;
        dataPoints = _processGraphData(invoiceData, _selectedPeriod);
        _loading = false;
      });
      _graphAnimController?.forward(from: 0.0);
    } catch (e) {
      print("Exception: $e");
      setState(() {
        _errorMsg = "Exception: $e";
        _loading = false;
      });
    }
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
      dataPoints = _processGraphData(invoices, _selectedPeriod);
      _selectedPointIndex = null;
      _selectedPointLocal = null;
    });
    _graphAnimController?.forward(from: 0.0);
  }

  List<SalesPoint> _processGraphData(List<Map<String, dynamic>> invoiceData, String period) {
    List<SalesPoint> points = [];
    List<Map<String, dynamic>> sorted = List<Map<String, dynamic>>.from(invoiceData);
    sorted.sort((a, b) => (a["date"] as String).compareTo(b["date"] as String));
    if (period == "Daily") {
      Map<String, double> dayMap = {};
      for (var inv in sorted) {
        String day = DateFormat('yyyy-MM-dd').format(DateTime.parse(inv["date"]));
        dayMap[day] = (dayMap[day] ?? 0) + (inv["total"] as num).toDouble();
      }
      points = dayMap.entries.map((e) => SalesPoint(e.key, e.value)).toList();
    } else if (period == "Weekly") {
      Map<String, double> weekMap = {};
      for (var inv in sorted) {
        DateTime dt = DateTime.parse(inv["date"]);
        String weekStr = DateFormat("w").format(dt);
        int week = 0;
        try {
          week = int.parse(weekStr);
        } catch (e) {
          print("Failed to parse week number: '$weekStr' from date: '${inv["date"]}'");
          continue; // skip this entry
        }
        String key = "${dt.year}-W$week";
        weekMap[key] = (weekMap[key] ?? 0) + (inv["total"] as num).toDouble();
      }
      points = weekMap.entries.map((e) => SalesPoint(e.key, e.value)).toList();
    } else if (period == "Monthly") {
      Map<String, double> monthMap = {};
      for (var inv in sorted) {
        String month = DateFormat('yyyy-MM').format(DateTime.parse(inv["date"]));
        monthMap[month] = (monthMap[month] ?? 0) + (inv["total"] as num).toDouble();
      }
      points = monthMap.entries.map((e) => SalesPoint(e.key, e.value)).toList();
    } else if (period == "Yearly") {
      Map<String, double> yearMap = {};
      for (var inv in sorted) {
        String year = DateFormat('yyyy').format(DateTime.parse(inv["date"]));
        yearMap[year] = (yearMap[year] ?? 0) + (inv["total"] as num).toDouble();
      }
      points = yearMap.entries.map((e) => SalesPoint(e.key, e.value)).toList();
    } else {
      double sum = sorted.fold(0.0, (prev, e) => prev + (e["total"] as num).toDouble());
      points = [SalesPoint("Overall", sum)];
    }
    // Ensure we have at least one point; if none, provide zero-points across the day for visual parity.
    if (points.isEmpty) {
      // If Daily, create hourly 0-data points to emulate example graph baseline
      if (period == "Daily") {
        for (int h = 0; h < 24; h += 2) {
          points.add(SalesPoint('${h.toString().padLeft(2, '0')}:00', 0));
        }
      }
    }
    return points;
  }

  // total of points
  double _totalForPoints(List<SalesPoint> pts) => pts.fold(0.0, (p, e) => p + e.value);

  // determine overview label and color based on trend between first and last point
  Map<String, dynamic> _computeOverview(List<SalesPoint> pts) {
    if (pts.isEmpty) return {'label': 'No data', 'color': Colors.grey};
    if (pts.length == 1) {
      final v = pts.first.value;
      if (v <= 0) return {'label': 'No data', 'color': Colors.grey};
      return {'label': 'Stable', 'color': Colors.green};
    }

    final double first = pts.first.value;
    final double last = pts.last.value;

    // If first is 0, use presence/absence to determine trend
    if (first == 0) {
      if (last == 0) return {'label': 'Stable', 'color': Colors.grey};
      return {'label': 'Increasing', 'color': Colors.green};
    }

    final double pct = ((last - first) / first) * 100.0;

    if (pct >= 20) {
      return {'label': 'Increasing', 'color': Colors.green};
    } else if (pct >= 5) {
      return {'label': 'Good', 'color': Colors.lightGreen};
    } else if (pct > -5) {
      return {'label': 'Stable', 'color': Colors.blueGrey};
    } else if (pct > -20) {
      return {'label': 'Need attention', 'color': Colors.orange};
    } else {
      return {'label': 'Terrible', 'color': Colors.red};
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 24,
      backgroundImage: AssetImage("assets/images/avatar.png"),
    );

    final overview = _computeOverview(dataPoints);
    final totalSales = _totalForPoints(dataPoints);

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _errorMsg != null
              ? Center(child: Text(_errorMsg!, style: const TextStyle(color: Colors.red)))
              : Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(Icons.search, color: Colors.grey, size: 22),
                          const SizedBox(width: 6),
                          const Text(
                            "Dashboard",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            "Rewas L. Dean",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                    decoration: BoxDecoration(
                      color: const Color(0xFF23262D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Oh Bsgo Voeh nw",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _dashboardCard(
                      title: "Today's sales",
                      value: todaysSales != null ? "₹${todaysSales!.toStringAsFixed(2)}" : "-",
                      sub: "",
                      icon: Icons.bar_chart,
                      color: const Color(0xFF208AFF),
                    ),
                    const SizedBox(width: 12),
                    _dashboardCard(
                      title: "Pending Orders",
                      value: pendingOrdersCount != null ? pendingOrdersCount.toString() : "-",
                      sub: "",
                      icon: Icons.shopping_cart_outlined,
                      color: const Color(0xFFFFB020),
                    ),
                    const SizedBox(width: 12),
                    _dashboardCard(
                      title: "Low stock",
                      value: "12 items",
                      sub: "\u2022 609 S\$8,405.90",
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF6DD9A6),
                    ),
                    const SizedBox(width: 12),
                    _dashboardCard(
                      title: "Earnings",
                      value: "\$5,800",
                      sub: "\u2022 685 S\$8,902.90",
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF208AFF),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.grey[400]!,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: 180,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedPeriod,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  dropdownColor: Colors.white,
                                  items: _periods.map((String period) {
                                    return DropdownMenuItem<String>(
                                      value: period,
                                      child: Text(period),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      _onPeriodChanged(newValue);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Graph area wrapped in LayoutBuilder to compute positions for hit detection
                      SizedBox(
                        height: 280,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 40, left: 8, right: 8),
                          child: AnimatedBuilder(
                            animation: _graphAnimController!,
                            builder: (context, child) {
                              return _salesGraph(dataPoints, 1.0);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      // Below the graph: total sales and overview single-word status
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Sales', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                  const SizedBox(height: 6),
                                  Text(_currency.format(totalSales), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: overview['color'] as Color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      overview['label'] as String,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: overview['color'] as Color),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      // Optionally show more details
                                      final snack = '${overview['label']} — total ${_currency.format(totalSales)}';
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snack)));
                                    },
                                    icon: Icon(Icons.info_outline, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Container(
        width: 200,
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 21),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New sales graph that supports area fill + grid + tooltip on hit
  Widget _salesGraph(List<SalesPoint> points, double animValue) {
    if (points.isEmpty) {
      return Center(child: Text("No sales data for selected period.", style: TextStyle(color: Colors.grey)));
    }

    final double yLabelWidth = 70; // same as painter
    final double leftMargin = yLabelWidth + 12;
    final double rightMargin = 20;
    final double bottomMargin = 10;
    final double topMargin = 18;

    return LayoutBuilder(builder: (context, constraints) {
      final Size size = Size(constraints.maxWidth, constraints.maxHeight);
      final double graphWidth = size.width - leftMargin - rightMargin;
      final double pad = points.length > 1 ? (graphWidth / (points.length - 1)) : 0;
      final double maxY = points.map((e) => e.value).fold(0.0, (prev, val) => val > prev ? val : prev);

      // compute local graph points (same logic as painter)
      final List<Offset> graphPoints = [];
      for (int i = 0; i < points.length; i++) {
        final double x = leftMargin + pad * i;
        final double graphHeight = size.height - topMargin - bottomMargin;
        final double y = topMargin + graphHeight - ((points[i].value / (maxY == 0 ? 1 : maxY)) * graphHeight);
        graphPoints.add(Offset(x, y));
      }

      return Stack(
        children: [
          // Painter draws curve + fill + grid + points
          CustomPaint(
            size: size,
            painter: SalesGraphPainter(
              points,
              animValue,
              maxY,
              pad,
              leftMargin,
              topMargin,
              bottomMargin,
              rightMargin,
            ),
          ),

          // Gesture detector overlays the graph for hit testing
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                final local = details.localPosition;
                _handleGraphTap(local, graphPoints, points);
              },
              onPanDown: (details) {
                final local = details.localPosition;
                _handleGraphTap(local, graphPoints, points);
              },
              onPanUpdate: (details) {
                final local = details.localPosition;
                _handleGraphTap(local, graphPoints, points);
              },
              onTap: () {
                // if tapped outside a point, hide tooltip after short delay
                // kept intentionally simple: hide if no index selected
                if (_selectedPointIndex == null) {
                  setState(() {
                    _selectedPointLocal = null;
                    _selectedPointLabel = null;
                  });
                }
              },
            ),
          ),

          // Tooltip
          if (_selectedPointIndex != null && _selectedPointLocal != null)
            Positioned(
              // position tooltip above the point; clamp inside graph bounds
              left: (_selectedPointLocal!.dx - 60).clamp(0.0, size.width - 120),
              top: (_selectedPointLocal!.dy - 48).clamp(0.0, size.height - 40),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedPointLabel ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // show value with currency formatting
                        _currency.format(points[_selectedPointIndex!].value),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  // Fixed null-safety safe handleGraphTap
  void _handleGraphTap(Offset local, List<Offset> graphPoints, List<SalesPoint> points) {
    if (graphPoints.isEmpty || points.isEmpty) {
      setState(() {
        _selectedPointIndex = null;
        _selectedPointLocal = null;
        _selectedPointLabel = null;
      });
      return;
    }

    // Find nearest point by distance (within a threshold)
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

    // If we found a nearest index and it's within the threshold, select it.
    if (nearestIdx != null && nearestDist <= threshold) {
      final int idx = nearestIdx; // non-nullable local copy
      setState(() {
        _selectedPointIndex = idx;
        _selectedPointLocal = graphPoints[idx];
        // create a compact label for X (if it's a full date, shorten it)
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
        } catch (_) {
          // ignore parsing errors and fall back to original label
        }
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
}

class SalesPoint {
  final String xLabel;
  final double value;
  SalesPoint(this.xLabel, this.value);
}

// Painter draws grid, smooth line, filled area, dots and highlighted point
class SalesGraphPainter extends CustomPainter {
  final List<SalesPoint> points;
  final double animValue;
  final double maxY;
  final double pad;
  final double leftMargin;
  final double topMargin;
  final double bottomMargin;
  final double rightMargin;

  SalesGraphPainter(this.points, this.animValue, this.maxY, this.pad, this.leftMargin, this.topMargin,
      this.bottomMargin, this.rightMargin);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double graphWidth = size.width - leftMargin - rightMargin;
    final double graphHeight = size.height - topMargin - bottomMargin;

    // compute points positions
    final List<Offset> graphPoints = [];
    for (int i = 0; i < points.length; i++) {
      final double x = leftMargin + pad * i;
      final double y = topMargin + graphHeight - ((points[i].value / (maxY == 0 ? 1 : maxY)) * graphHeight) * animValue;
      graphPoints.add(Offset(x, y));
    }

    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    // horizontal grid lines
    int nGrid = 6;
    for (int i = 0; i < nGrid; i++) {
      double y = topMargin + graphHeight - (i / (nGrid - 1)) * graphHeight;
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width - rightMargin, y), gridPaint);
    }

    // Fill area under curve
    final Path fillPath = Path();
    if (graphPoints.isNotEmpty) {
      fillPath.moveTo(graphPoints[0].dx, graphPoints[0].dy);
      for (int i = 0; i < graphPoints.length - 1; i++) {
        final p1 = graphPoints[i];
        final p2 = graphPoints[i + 1];
        final controlX = (p1.dx + p2.dx) / 2;
        fillPath.quadraticBezierTo(controlX, p1.dy, p2.dx, p2.dy);
      }
      // go down to bottom and close
      fillPath.lineTo(graphPoints.last.dx, topMargin + graphHeight);
      fillPath.lineTo(graphPoints.first.dx, topMargin + graphHeight);
      fillPath.close();
    }

    // area gradient
    final Rect areaRect = Rect.fromLTRB(leftMargin, topMargin, size.width - rightMargin, topMargin + graphHeight);
    final Gradient areaGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.blue.withOpacity(0.12), Colors.blue.withOpacity(0.03)],
    );
    final Paint fillPaint = Paint()..shader = areaGradient.createShader(areaRect);
    canvas.drawPath(fillPath, fillPaint);

    // Stroke path
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

    // Draw dots
    final Paint dotPaint = Paint()..color = Colors.white;
    final Paint dotEdge = Paint()
      ..color = Colors.blue.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < graphPoints.length; i++) {
      final p = graphPoints[i];
      canvas.drawCircle(p, 5.5, dotPaint);
      canvas.drawCircle(p, 5.5, dotEdge);
    }

    // Draw tick Y labels and dashed minor grid lines already handled above
    final TextStyle yAxisStyle = TextStyle(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.w500);
    for (int j = 0; j < nGrid; j++) {
      double y = topMargin + graphHeight - ((j / (nGrid - 1)) * graphHeight);
      double val = (maxY / (nGrid - 1)) * j;
      final tp = TextPainter(
        text: TextSpan(text: "₹${val.toStringAsFixed(0)}", style: yAxisStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: leftMargin - 8);
      tp.paint(canvas, Offset(leftMargin - tp.width - 8, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant SalesGraphPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.animValue != animValue ||
        oldDelegate.maxY != maxY ||
        oldDelegate.pad != pad;
  }
}