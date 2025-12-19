// lib/src/services/order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/auth_helper.dart';
import '../models/order_model.dart';
import '../../consts.dart';

class OrderService {
  final String apiToken;
  final String apiUrl;

  OrderService({required this.apiToken, required this.apiUrl});

  Future<List<OrderModel>> fetchPendingOrders({required String storeId, required String branch}) async {
    final url = Uri.parse('${apiUrl}order/store-pending-orders/');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);
    final resp = await http.post(url, headers: headers, body: jsonEncode({"store_id": storeId, "branch": branch}));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final rawList = data is Map && data['pending_orders'] is List ? data['pending_orders'] as List : <dynamic>[];
      return rawList.map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    throw HttpExceptionWithBody(resp.statusCode, resp.body);
  }

  Future<List<OrderModel>> fetchOrdersByStatus({
    required String status,
    required String storeId,
    required String branch,
    int page = 1,
    int limit = 10,
  }) async {
    final url = Uri.parse('${apiUrl}order/orders-by-status');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);
    final resp = await http.post(url, headers: headers, body: jsonEncode({
      "status": status,
      "store_id": storeId,
      "branch": branch,
      "page": page,
      "limit": limit,
    }));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final rawList = data is Map && data['orders'] is List ? data['orders'] as List : <dynamic>[];
      return rawList.map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    throw HttpExceptionWithBody(resp.statusCode, resp.body);
  }

  Future<void> acceptOrder({required String orderId, required String storeId, required String branch}) async {
    final url = Uri.parse('${apiUrl}order/accept-order');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);
    final resp = await http.post(url, headers: headers, body: jsonEncode({"order_id": orderId, "store_id": storeId, "branch": branch}));
    if (resp.statusCode != 200) throw HttpExceptionWithBody(resp.statusCode, resp.body);
  }

  Future<void> rejectOrder({required String orderId, required String storeId, required String branch, required String reason}) async {
    final url = Uri.parse('${apiUrl}order/reject-order');
    final headers = await AuthHelper.getAuthHeaders(apiToken: apiToken);
    final resp = await http.post(url, headers: headers, body: jsonEncode({"order_id": orderId, "store_id": storeId, "branch": branch, "reason": reason}));
    if (resp.statusCode != 200) throw HttpExceptionWithBody(resp.statusCode, resp.body);
  }
}

class HttpExceptionWithBody implements Exception {
  final int code;
  final String body;
  HttpExceptionWithBody(this.code, this.body);

  @override
  String toString() => 'HTTP $code: $body';
}