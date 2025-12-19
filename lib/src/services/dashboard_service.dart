// lib/src/services/dashboard_service.dart
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../consts.dart';
import '../models/dashboardModels.dart';
import 'api_client.dart';

class DashboardService {
  final ApiClient _client;

  // Constructor now takes ApiClient (which we provide in main.dart)
  DashboardService({ApiClient? client}) 
      : _client = client ?? ApiClient(baseUrl: API_URL);

  Future<double> fetchTodaysSales() async {
    final resp = await _client.get('invoices/todays-salesamount-value');
    final j = jsonDecode(resp.body);
    double sales = 0.0;
    if (j is Map && j['total_sales'] != null) {
      sales = (j['total_sales'] as num).toDouble();
    } else if (j is Map && j['sales'] != null) {
      sales = (j['sales'] as num).toDouble();
    }
    return sales;
  }

  Future<int> fetchPendingOrdersCount(String storeId, String branch) async {
    final resp = await _client.post(
      'order/pending-orders-count',
      body: {"store_id": storeId, "branch": branch},
    );
    final j = jsonDecode(resp.body);
    if (j is Map && j.containsKey('pending_orders_count')) {
      return (j['pending_orders_count'] as num).toInt();
    } else if (j is Map && j.containsKey('count')) {
      return (j['count'] as num).toInt();
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> fetchPastYearInvoices(String storeId, String branch) async {
    try {
      final resp = await _client.get('invoices/past-year-invoices?store_id=$storeId&branch=$branch');
      final j = jsonDecode(resp.body);
      if (j is Map && j['invoices'] is List) {
        return List<Map<String, dynamic>>.from(j['invoices']);
      }
    } catch (_) {
      // Return empty list if call fails to allow screen to show partial data
    }
    return [];
  }

  List<SalesPoint> processGraphData(List<Map<String, dynamic>> invoiceData, String period) {
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
    } else if (period == "Monthly") {
      Map<String, double> monthMap = {};
      for (var inv in sorted) {
        String month = DateFormat('yyyy-MM').format(DateTime.parse(inv["date"]));
        monthMap[month] = (monthMap[month] ?? 0) + (inv["total"] as num).toDouble();
      }
      points = monthMap.entries.map((e) => SalesPoint(e.key, e.value)).toList();
    }
    // Default fallback if empty
    if (points.isEmpty) {
      points = [SalesPoint(DateFormat('yyyy-MM-dd').format(DateTime.now()), 0.0)];
    }
    return points;
  }

  Future<DashboardData> fetchAll(String period) async {
    // 1. Get user details for store_id and branch
    final userResp = await _client.get('users/me');
    final userJson = jsonDecode(userResp.body);
    final String? storeId = userJson['store_id'];
    final String? branch = userJson['branch'];
    
    if (storeId == null || branch == null) {
      throw Exception("User's store_id or branch missing.");
    }

    // 2. Fetch all components using the client (which has the correct tokens)
    final todaysSales = await fetchTodaysSales();
    final pending = await fetchPendingOrdersCount(storeId, branch);
    final invoices = await fetchPastYearInvoices(storeId, branch);
    final points = processGraphData(invoices, period);

    return DashboardData(
      todaysSales: todaysSales,
      pendingOrdersCount: pending,
      invoices: invoices,
      dataPoints: points,
    );
  }
}
