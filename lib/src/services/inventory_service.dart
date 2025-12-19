import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../../consts.dart';
import '../models/prouduct_model.dart';

class InventoryService {
  static const String apiToken = '0ff738d516ce887efe7274d43acd8043';

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accessToken = prefs.getString('access_token');
    final String tokenTypeRaw = prefs.getString('token_type') ?? 'Bearer';
    final String tokenType = (tokenTypeRaw).trim().isEmpty ? 'Bearer' : tokenTypeRaw.trim();
    final String authorizationHeader = '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} ${accessToken ?? ""}';
    return {
      'Content-Type': 'application/json',
      'x-api-token': apiToken,
      'Authorization': authorizationHeader,
    };
  }

  Future<Map<String, dynamic>> fetchUser() async {
    final headers = await _getAuthHeaders();
    final resp = await http.get(Uri.parse('${API_URL}users/me'), headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('User API Error ${resp.statusCode}: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<List<ProductModel>> fetchInventory(String storeId, String branch) async {
    final headers = await _getAuthHeaders();
    final resp = await http.get(Uri.parse('${API_URL}store/inventory/$storeId/$branch'), headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Inventory API Error ${resp.statusCode}: ${resp.body}');
    }
    final body = jsonDecode(resp.body);
    List<Map<String, dynamic>> items = [];
    if (body is List) items = List<Map<String, dynamic>>.from(body);
    else if (body is Map && body['inventory'] is List) items = List<Map<String, dynamic>>.from(body['inventory']);
    return items.map((m) => ProductModel.fromJson(m)).toList();
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final headers = await _getAuthHeaders();
    final resp = await http.get(Uri.parse('${API_URL}category'), headers: headers);
    if (resp.statusCode != 200) {
      return <CategoryModel>[];
    }
    final body = jsonDecode(resp.body);
    List<Map<String, dynamic>> items = [];
    if (body is List) {
      items = List<Map<String, dynamic>>.from(body);
    } else if (body is Map && body['data'] is List) {
      items = List<Map<String, dynamic>>.from(body['data']);
    }
    return items.map((m) => CategoryModel.fromJson(m)).toList();
  }
}