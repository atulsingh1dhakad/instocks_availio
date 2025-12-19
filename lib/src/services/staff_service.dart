// lib/src/services/staff_service.dart
import 'dart:convert';
import '../models/staff_model.dart';
import 'api_client.dart';
import '../../consts.dart';

class StaffService {
  final ApiClient _client;

  StaffService({ApiClient? client}) 
      : _client = client ?? ApiClient(baseUrl: API_URL);

  Future<List<StaffModel>> fetchStaff() async {
    final resp = await _client.get('store/store-employee-details');
    final body = jsonDecode(resp.body);
    List<dynamic> raw = [];
    if (body is List) {
      raw = body;
    } else if (body is Map && body['data'] is List) {
      raw = body['data'];
    } else if (body is Map && body['employees'] is List) {
      raw = body['employees'];
    }
    return raw.whereType<Map<String, dynamic>>().map((m) => StaffModel.fromJson(m)).toList();
  }

  Future<void> createStaff(Map<String, dynamic> payload) async {
    await _client.post('users/create-fresh-user', body: payload);
  }

  Future<void> deleteStaff(String userId) async {
    await _client.post('users/delete-user', body: {'user_id': userId});
  }
}
