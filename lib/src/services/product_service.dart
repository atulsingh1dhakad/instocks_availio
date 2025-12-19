import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_create_model.dart';

class ProductService {
  static const String apiTokenStatic = '0ff738d516ce887efe7274d43acd8043';

  Future<Map<String, String>> _authHeaders({bool multipart = false, String? apiToken}) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final tokenTypeRaw = prefs.getString('token_type') ?? 'Bearer';
    final tokenType = tokenTypeRaw.trim().isEmpty ? 'Bearer' : tokenTypeRaw.trim();
    final authorization = '${tokenType[0].toUpperCase()}${tokenType.substring(1).toLowerCase()} ${accessToken ?? ""}';
    final token = apiToken ?? apiTokenStatic;
    final headers = <String, String>{
      if (!multipart) 'Content-Type': 'application/json',
      'x-api-token': token,
      'Authorization': authorization,
    };
    return headers;
  }

  // Upload image and return uploaded URL (or throw)
  Future<String> uploadProductImage({
    required XFile file,
    required String apiUrl,
    required String storeId,
    String? apiToken,
  }) async {
    final headers = await _authHeaders(multipart: true, apiToken: apiToken);
    final uri = Uri.parse('${apiUrl}products/upload-product-image').replace(queryParameters: {'store_id': storeId ?? ''});
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);

    final bytes = await file.readAsBytes();
    final multipartFile = http.MultipartFile.fromBytes('image', bytes, filename: file.name);
    request.files.add(multipartFile);

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final body = jsonDecode(resp.body);
      final url = body['url'] ?? body['data']?['url'] ?? '';
      if (url == null || url.toString().isEmpty) throw Exception('Upload did not return url');
      return url.toString();
    } else {
      throw Exception('Image upload failed (${resp.statusCode}): ${resp.body}');
    }
  }

  // Add many products
  Future<void> addProducts({
    required List<Map<String, dynamic>> productsJson,
    required String apiUrl,
    String? apiToken,
  }) async {
    final headers = await _authHeaders(multipart: false, apiToken: apiToken);
    final url = Uri.parse('${apiUrl}products/add-many');
    final resp = await http.post(url, headers: headers, body: jsonEncode(productsJson));
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      String message = resp.body;
      try {
        final b = jsonDecode(resp.body);
        if (b is Map && b['message'] != null) message = b['message'].toString();
      } catch (_) {}
      throw Exception('Add products failed (${resp.statusCode}): $message');
    }
  }

  // Optionally: add single
  Future<void> addProduct({
    required ProductCreate product,
    required String apiUrl,
    String? apiToken,
  }) async {
    await addProducts(productsJson: [product.toJson()], apiUrl: apiUrl, apiToken: apiToken);
  }
}