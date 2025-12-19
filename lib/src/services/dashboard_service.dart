import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/dashboardModels.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../consts.dart';

class DashboardService {
  static const String apiToken = API_TOKEN; // keep as earlier or move to consts

  Future<Map<String, String>> _buildAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('access_token');
    final String? tokenTypeRaw = prefs.getString('token_type');
    final String tokenType = (tokenTypeRaw ?? 'Bearer').trim();
    final String? useAccessToken = accessToken != null && accessToken.trim().isNotEmpty ? accessToken.trim() : null;
    final String authorizationHeader =
        '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} ${useAccessToken ?? ""}';
    return {
      'Content-Type': 'application/json',
      'x-api-token': apiToken,
      'Authorization': authorizationHeader,
    };
  }

  Future<String?> _fetchUserStoreId() async {
    final headers = await _buildAuthHeaders();
    final resp = await http.get(Uri.parse('${API_URL}users/me'), headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('User API Error ${resp.statusCode}: ${resp.body}');
    }
    final json = jsonDecode(resp.body);
    return json['store_id'] as String?;
  }

  Future<double> fetchTodaysSales() async {
    final headers = await _buildAuthHeaders();
    final resp = await http.get(Uri.parse('${API_URL}invoices/todays-salesamount-value'), headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Todays sales API Error ${resp.statusCode}: ${resp.body}');
    }
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
    final headers = await _buildAuthHeaders();
    final resp = await http.post(
      Uri.parse('${API_URL}order/pending-orders-count'),
      headers: headers,
      body: jsonEncode({"store_id": storeId, "branch": branch}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Pending orders API Error ${resp.statusCode}: ${resp.body}');
    }
    final j = jsonDecode(resp.body);
    if (j is Map && j.containsKey('pending_orders_count')) {
      return (j['pending_orders_count'] as num).toInt();
    } else if (j is Map && j.containsKey('pending_orders')) {
      return (j['pending_orders'] as num).toInt();
    } else if (j is Map && j.containsKey('count')) {
      return (j['count'] as num).toInt();
    } else if (j is Map && j.containsKey('orders_count')) {
      return (j['orders_count'] as num).toInt();
    } else {
      throw Exception('Pending orders API unknown response: ${resp.body}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPastYearInvoices(String storeId, String branch) async {
    final headers = await _buildAuthHeaders();
    final resp = await http.get(Uri.parse('${API_URL}invoices/past-year-invoices?store_id=$storeId&branch=$branch'), headers: headers);
    if (resp.statusCode != 200) {
      // return empty list instead of throwing to allow showing no-data
      return [];
    }
    final j = jsonDecode(resp.body);
    if (j is Map && j['invoices'] is List) {
      return List<Map<String, dynamic>>.from(j['invoices']);
    }
    return [];
  }

  // Create SalesPoints according to period
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
    } else if (period == "Weekly") {
      Map<String, double> weekMap = {};
      for (var inv in sorted) {
        DateTime dt = DateTime.parse(inv["date"]);
        String weekStr = DateFormat("w").format(dt);
        int week = int.tryParse(weekStr) ?? 0;
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
    if (points.isEmpty && period == "Daily") {
      for (int h = 0; h < 24; h += 2) {
        points.add(SalesPoint('${h.toString().padLeft(2, '0')}:00', 0));
      }
    }
    return points;
  }

  Future<DashboardData> fetchAll(String period) async {
    // fetch user -> store id & branch
    final headers = await _buildAuthHeaders();
    final userResp = await http.get(Uri.parse('${API_URL}users/me'), headers: headers);
    if (userResp.statusCode != 200) {
      throw Exception('User API Error ${userResp.statusCode}: ${userResp.body}');
    }
    final userJson = jsonDecode(userResp.body);
    final String? storeId = userJson['store_id'];
    final String? branch = userJson['branch'];
    if (storeId == null || branch == null) {
      throw Exception("User's store_id or branch missing.");
    }

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