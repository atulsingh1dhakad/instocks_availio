// lib/src/services/recycle_service.dart
import 'dart:convert';
import '../models/recycle_item.dart';
import 'api_client.dart';
import '../../consts.dart';

class RecycleService {
  final ApiClient _client;

  RecycleService({ApiClient? client}) 
      : _client = client ?? ApiClient(baseUrl: API_URL);

  Future<List<RecycleItem>> fetchRecycleBin() async {
    final resp = await _client.get('products/recycle-bin');
    final body = jsonDecode(resp.body);
    List<dynamic> rawList = [];
    if (body is List) {
      rawList = body;
    } else if (body is Map && body['products'] is List) {
      rawList = body['products'];
    } else if (body is Map && body['data'] is List) {
      rawList = body['data'];
    }
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((m) => RecycleItem.fromJson(m))
        .toList();
  }

  Future<void> restoreProduct(int productId) async {
    await _client.post(
      'products/undel-prod',
      body: {"product_id": productId},
    );
  }

  Future<void> deleteProduct(int productId) async {
    await _client.delete(
      'products/per-del-prod',
      body: {"product_id": productId},
    );
  }

  Future<void> deleteAll() async {
    await _client.delete('products/per-del-all-prod');
  }
}
