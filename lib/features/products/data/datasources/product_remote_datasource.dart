import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/product_model.dart';

class ProductRemoteDataSource {
  final http.Client client;

  ProductRemoteDataSource({required this.client});

  // 1. GET: Fetch paginated products (with optional search)
  Future<({List<Product> items, int total})> getProductsFromServer({
    int page = 1,
    int limit = 30,
    String search = '',
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.getProducts).replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search.isNotEmpty) 'search': search,
      });

      final response = await client.get(
        uri,
        headers: ApiConfig.jsonHeaders,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List rawList = body['data'];
          final items = rawList.map((json) => Product.fromMap(json)).toList();
          final total = body['totalRecords'] as int? ?? 0;
          return (items: items, total: total);
        }
      }
    } catch (e) {
      print("Remote DataSource GET Error: $e");
    }
    return (items: <Product>[], total: 0);
  }

  // 2. POST: Add product (unchanged)
  Future<int> addProductToServer(Product product) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConfig.addProduct),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(product.toMap()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int newId = int.tryParse(data['id']?.toString() ?? '0') ?? 0;

        if (product.imagePath.isNotEmpty && newId > 0 && !product.imagePath.startsWith('http')) {
          await syncMultipartImage(newId, product.imagePath);
        }
        return newId;
      }
    } catch (e) {
      print("Remote DataSource POST Error: $e");
    }
    return 0;
  }

  // 3. PUT: Update product (unchanged)
  Future<bool> updateProductOnServer(Product product) async {
    try {
      final response = await client.put(
        Uri.parse(ApiConfig.updateProduct),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(product.toMap()),
      );

      if (response.statusCode == 200) {
        if (product.imagePath.isNotEmpty && product.id != null && !product.imagePath.startsWith('http')) {
          await syncMultipartImage(product.id!, product.imagePath);
        }
        return true;
      }
    } catch (e) {
      print("Remote DataSource PUT Error: $e");
    }
    return false;
  }

  // 4. DELETE: Soft-delete (unchanged)
  Future<bool> deleteProductFromServer(int id) async {
    try {
      final response = await client.delete(
        Uri.parse("${ApiConfig.deleteProduct}?id=$id"),
        headers: ApiConfig.jsonHeaders,
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Remote DataSource DELETE Error: $e");
    }
    return false;
  }

  // 5. Multi-part image upload (unchanged)
  Future<void> syncMultipartImage(int productId, String localPath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.uploadImage),
      );
      request.headers.addAll(ApiConfig.jsonHeaders);
      request.fields['product_id'] = productId.toString();
      request.files.add(await http.MultipartFile.fromPath('image', localPath));
      await request.send();
    } catch (e) {
      print("MVP Image Sync Upload Error: $e");
    }
  }

  // ─── Fetch categories ────────────────────────────────────────
Future<List<Map<String, dynamic>>> getCategories() async {
  try {
    final response = await client.get(
      Uri.parse("${ApiConfig.getProducts}?action=categories"),
      headers: ApiConfig.jsonHeaders,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] != null) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
    }
  } catch (e) {
    print("Remote DataSource Get Categories Error: $e");
  }
  return [];
}

// ─── Fetch units ──────────────────────────────────────────────
Future<List<Map<String, dynamic>>> getUnits() async {
  try {
    final response = await client.get(
      Uri.parse("${ApiConfig.getProducts}?action=units"),
      headers: ApiConfig.jsonHeaders,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] != null) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
    }
  } catch (e) {
    print("Remote DataSource Get Units Error: $e");
  }
  return [];
}
// ─── Fetch suppliers ──────────────────────────────────────────────
Future<List<Map<String, dynamic>>> getSuppliersFromServer() async {
final response = await client.get(
  Uri.parse("${ApiConfig.getSuppliers}?page=1&limit=1000"),
  headers: ApiConfig.jsonHeaders,
);

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);

    if (body['success'] == true) {
      return List<Map<String, dynamic>>.from(body['data']);
    }
  }

  return [];
}
}