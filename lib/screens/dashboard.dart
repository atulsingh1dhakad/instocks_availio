import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:instockavailio/consts.dart';
import 'package:instockavailio/screens/table.dart';
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
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 24,
      backgroundImage: AssetImage("assets/images/avatar.png"),
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: _loading
              ? Center(child: CircularProgressIndicator())
              : _errorMsg != null
              ? Center(child: Text(_errorMsg!, style: TextStyle(color: Colors.red)))
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
                      color: Color(0xFF23262D),
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
                      color: Color(0xFF208AFF),
                    ),
                    SizedBox(width: 12),
                    _dashboardCard(
                      title: "Pending Orders",
                      value: pendingOrdersCount != null ? pendingOrdersCount.toString() : "-",
                      sub: "",
                      icon: Icons.shopping_cart_outlined,
                      color: Color(0xFFFFB020),
                    ),
                    SizedBox(width: 12),
                    _dashboardCard(
                      title: "Low stock",
                      value: "12 items",
                      sub: "\u2022 609 S\$8,405.90",
                      icon: Icons.inventory_2_outlined,
                      color: Color(0xFF6DD9A6),
                    ),
                    SizedBox(width: 12),
                    _dashboardCard(
                      title: "Earnings",
                      value: "\$5,800",
                      sub: "\u2022 685 S\$8,902.90",
                      icon: Icons.account_balance_wallet_outlined,
                      color: Color(0xFF208AFF),
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
                    boxShadow: [
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
                            padding: EdgeInsets.symmetric(horizontal: 18),
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
                                  icon: Icon(Icons.arrow_drop_down),
                                  style: TextStyle(
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
                          Spacer(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Increase graph height and add more bottom padding for better label visibility
                      SizedBox(
                        height: 280, // Increased height for graph
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 40, left: 8, right: 8), // Add more bottom space
                          child: AnimatedBuilder(
                            animation: _graphAnimController!,
                            builder: (context, child) {
                              return _salesGraph(dataPoints, 1.0);
                            },
                          ),
                        ),
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
          boxShadow: [
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
                style: TextStyle(
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
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _salesGraph(List<SalesPoint> points, double animValue) {
    if (points.isEmpty) {
      return Center(child: Text("No sales data for selected period.", style: TextStyle(color: Colors.grey)));
    }
    double maxY = points.map((e) => e.value).fold(0.0, (prev, val) => val > prev ? val : prev);
    double pad = points.length > 1 ? (360 / (points.length - 1)) : 0; // Increased pad for more space between points
    return Container(
      width: double.infinity,
      height: 240, // Increased height for graph canvas
      child: CustomPaint(
        painter: SalesGraphPainter(points, animValue, maxY, pad),
      ),
    );
  }
}

class SalesPoint {
  final String xLabel;
  final double value;
  SalesPoint(this.xLabel, this.value);
}

class SalesGraphPainter extends CustomPainter {
  final List<SalesPoint> points;
  final double animValue;
  final double maxY;
  final double pad;

  SalesGraphPainter(this.points, this.animValue, this.maxY, this.pad);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double yLabelWidth = 70; // Fixed width for Y labels
    final double leftMargin = yLabelWidth + 12; // Margin for Y labels + some padding
    final double rightMargin = 20;
    final double bottomMargin =10; // Increased bottom margin for date labels
    final double topMargin = 18;

    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = Colors.blue;

    List<Offset> graphPoints = [];
    for (int i = 0; i < points.length; i++) {
      double x = leftMargin + pad * i;
      double graphHeight = size.height - topMargin - bottomMargin;
      double y = topMargin + graphHeight - ((points[i].value / (maxY == 0 ? 1 : maxY)) * graphHeight);
      graphPoints.add(Offset(x, y));
    }

    // Draw smooth curve using quadratic Bezier segments
    Path path = Path();
    if (graphPoints.isNotEmpty) {
      path.moveTo(graphPoints[0].dx, graphPoints[0].dy);
      for (int i = 0; i < graphPoints.length - 1; i++) {
        Offset p1 = graphPoints[i];
        Offset p2 = graphPoints[i + 1];
        double controlX = (p1.dx + p2.dx) / 2;
        path.quadraticBezierTo(controlX, p1.dy, p2.dx, p2.dy);
      }
    }
    canvas.drawPath(path, paint);

    // Draw dots
    for (int i = 0; i < graphPoints.length; i++) {
      canvas.drawCircle(graphPoints[i], 8, dotPaint);
      canvas.drawCircle(graphPoints[i], 4, Paint()..color = Colors.black);
    }

    // Draw X labels (dates) below points
    final textStyle = TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600);
    for (int i = 0; i < graphPoints.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: points[i].xLabel, style: textStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: pad * 0.8);
      tp.paint(canvas, Offset(graphPoints[i].dx - tp.width / 3, size.height - bottomMargin + 20));
    }

    // Draw Y labels (prices) along left margin, all at same x position
    final yAxisStyle = TextStyle(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.w500);
    int nGrid = 5;
    for (int j = 0; j < nGrid; j++) {
      double graphHeight = size.height - topMargin - bottomMargin;
      double y = topMargin + graphHeight - ((j / (nGrid - 1)) * graphHeight);
      double val = (maxY / (nGrid - 1)) * j;
      final tp = TextPainter(
        text: TextSpan(text: "₹${val.toStringAsFixed(0)}", style: yAxisStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: yLabelWidth);
      tp.paint(canvas, Offset(leftMargin - yLabelWidth, y - tp.height / 2));
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width - rightMargin, y),
        Paint()
          ..color = Colors.grey.shade300
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}