import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/supplier_model.dart';

class SupplierRemoteDatasource {
  final String baseUrl;
  final http.Client client;

  SupplierRemoteDatasource({required this.baseUrl, required this.client});

  // Fetch dynamic categories directly from the database table
  Future<List<String>> fetchDatabaseCategories() async {
    // Reuses the consolidated categories endpoint route from products
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/products/products.php?action=categories');
    final response = await client.get(uri, headers: ApiConfig.jsonHeaders);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded['success'] == true) {
        final List data = decoded['data'] ?? [];
        return data.map((item) => item['category_name'].toString()).toList();
      }
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchSuppliers({
    required int page,
    required int limit,
    String? search,
    String? status,
    String? sort,
    String? order,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      if (sort != null) 'sort': sort,
      if (order != null) 'order': order,
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/suppliers/suppliers.php').replace(queryParameters: queryParams);
    final response = await client.get(uri, headers: ApiConfig.jsonHeaders);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List dynamicList = decoded['data'] ?? [];
      final models = dynamicList.map((item) => SupplierModel.fromJson(item)).toList();
      
      return {
        'totalRecords': decoded['totalRecords'] ?? 0,
        'totalPages': decoded['totalPages'] ?? 1,
        'data': models,
      };
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to load suppliers.');
    }
  }

  Future<SupplierModel> fetchSupplierById(int id) async {
    final response = await client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/suppliers/suppliers.php?id=$id'),
      headers: ApiConfig.jsonHeaders,
    );
    if (response.statusCode == 200) {
      return SupplierModel.fromJson(json.decode(response.body)['data']);
    } else {
      throw Exception('Supplier resource not found.');
    }
  }

  Future<int> addSupplier(SupplierModel model) async {
    final response = await client.post(
      Uri.parse(ApiConfig.addSupplier),
      headers: ApiConfig.jsonHeaders, // ✅ Fix: Replaced raw array to use complete ngrok headers
      body: json.encode(model.toJson()),
    );
    final decoded = json.decode(response.body);
    if (decoded['success'] == true) {
      return decoded['id'];
    } else {
      throw Exception(decoded['message'] ?? 'Failed to create supplier.');
    }
  }

  Future<void> editSupplier(SupplierModel model) async {
    final response = await client.put(
      Uri.parse(ApiConfig.updateSupplier),
      headers: ApiConfig.jsonHeaders, // ✅ Fix: Replaced raw array to use complete ngrok headers
      body: json.encode(model.toJson()),
    );
    final decoded = json.decode(response.body);
    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to update supplier.');
    }
  }

  Future<void> removeSupplier(int id) async {
    final response = await client.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/suppliers/suppliers.php?id=$id'),
      headers: ApiConfig.jsonHeaders,
    );
    final decoded = json.decode(response.body);
    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to perform deletion.');
    }
  }

  Future<String> uploadImage(int supplierId, File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.uploadSupplierImage}?supplier_id=$supplierId'),
    );
    request.headers.addAll({'ngrok-skip-browser-warning': 'true'}); // ✅ Fix: Applied bypass to multi-part upload form boundary stream
    request.files.add(await http.MultipartFile.fromPath('image', file.path));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = json.decode(response.body);
    
    if (response.statusCode == 200 && decoded['success'] == true) {
      return decoded['image_path'];
    } else {
      throw Exception(decoded['message'] ?? 'Image upload failure.');
    }
  }
}