import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/product_model.dart';

class ProductRemoteDataSource {
  final http.Client client;

  ProductRemoteDataSource({required this.client});

  // ============================================================
  // PRIVATE RESPONSE DECODER
  // ============================================================

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) {
      throw Exception('Server returned an empty response.');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Invalid response received from server.');
    }

    final body = Map<String, dynamic>.from(decoded);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body['message']?.toString() ?? 'Server error (${response.statusCode}).',
      );
    }

    return body;
  }

  // ============================================================
  // 1. GET PRODUCTS
  // ============================================================

  Future<({List<Product> items, int total})> getProductsFromServer({
    int page = 1,
    int limit = 30,
    String search = '',
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.getProducts).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      final response = await client.get(uri, headers: ApiConfig.jsonHeaders);
      final body = _decodeResponse(response);

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Unable to load products.',
        );
      }

      final rawData = body['data'];

      if (rawData is! List) {
        throw Exception('Invalid product data received from server.');
      }

      final items = rawData
          .map(
            (json) => Product.fromMap(Map<String, dynamic>.from(json as Map)),
          )
          .toList();

      final total = int.tryParse(body['totalRecords']?.toString() ?? '0') ?? 0;

      return (items: items, total: total);
    } on FormatException {
      throw Exception('Invalid response received from server.');
    } catch (e, st) {
      debugPrint('Product GET Error: $e\n$st');
      rethrow;
    }
  }

  // ============================================================
  // 2. POST - ADD PRODUCT
  // ============================================================

  Future<int> addProductToServer(Product product) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConfig.addProduct),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(product.toMap()),
      );

      final data = _decodeResponse(response);

      if (data['success'] != true) {
        throw Exception(
          data['message']?.toString() ?? 'Unable to add product.',
        );
      }

      final newId = int.tryParse(data['id']?.toString() ?? '') ?? 0;

      if (newId <= 0) {
        throw Exception(
          'Product was created but the server returned an invalid product ID.',
        );
      }

      if (product.imagePath.trim().isNotEmpty &&
          !product.imagePath.startsWith('http')) {
        try {
          await syncMultipartImage(newId, product.imagePath);
        } catch (e, st) {
          debugPrint('Product created successfully, but image upload failed: $e\n$st');
        }
      }

      return newId;
    } on FormatException {
      throw Exception('Invalid response received from server.');
    } catch (e, st) {
      debugPrint('Product POST Error: $e\n$st');
      rethrow;
    }
  }

  // ============================================================
  // 3. PUT - UPDATE PRODUCT
  // ============================================================

Future<bool> updateProductOnServer(Product product) async {
    try {
      if (product.id == null || product.id! <= 0) {
        throw Exception('Invalid product ID.');
      }

      final payload = product.toMap();
      payload['id'] = product.id;
      payload['current_stock'] = product.quantity;

      if (!payload.containsKey('category_id') ||
          payload['category_id'] == null) {
        final categories = await _getCategoriesFromServer();
        final match = categories.firstWhere(
          (c) =>
              c['name'].toString().toLowerCase().trim() ==
              product.category.toLowerCase().trim(),
          orElse: () => categories.isNotEmpty ? categories.first : {'id': 1},
        );
        payload['category_id'] = match['id'];
      }

      final response = await client.put(
        Uri.parse(ApiConfig.updateProduct),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(payload),
      );

      final data = _decodeResponse(response);

      if (data['success'] != true) {
        throw Exception(
          data['message']?.toString() ?? 'Unable to update product.',
        );
      }

      if (product.imagePath.trim().isNotEmpty &&
          !product.imagePath.startsWith('http')) {
        try {
          await syncMultipartImage(product.id!, product.imagePath);
        } catch (e, st) {
          debugPrint('Product updated successfully, but image upload failed: $e\n$st');
        }
      }

      return true;
    } on FormatException {
      throw Exception('Invalid response received from server.');
    } catch (e, st) {
      debugPrint('Product PUT Error: $e\n$st');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getCategoriesFromServer() async {
    try {
      final response = await client.get(
        Uri.parse(ApiConfig.productCategories),
        headers: ApiConfig.jsonHeaders,
      );

      final body = _decodeResponse(response);
      if (body['success'] == true && body['data'] is List) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
    } catch (_) {}
    return [];
  }

  // ============================================================
  // 4. DELETE PRODUCT
  // ============================================================

  Future<bool> deleteProductFromServer(int id) async {
    try {
      if (id <= 0) {
        throw Exception('Invalid product ID.');
      }

      final response = await client.delete(
        Uri.parse('${ApiConfig.deleteProduct}?id=$id'),
        headers: ApiConfig.jsonHeaders,
      );

      final data = _decodeResponse(response);

      if (data['success'] != true) {
        throw Exception(
          data['message']?.toString() ?? 'Unable to delete product.',
        );
      }

      return true;
    } on FormatException {
      throw Exception('Invalid response received from server.');
    } catch (e, st) {
      debugPrint('Product DELETE Error: $e\n$st');
      rethrow;
    }
  }

  // ============================================================
  // 5. MULTIPART IMAGE UPLOAD
  // ============================================================

  Future<void> syncMultipartImage(int productId, String localPath) async {
    try {
      if (productId <= 0) {
        throw Exception('Invalid product ID for image upload.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.uploadImage),
      );

      request.headers.addAll(ApiConfig.jsonHeaders);
      request.fields['product_id'] = productId.toString();
      request.files.add(await http.MultipartFile.fromPath('image', localPath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Product image upload failed (${response.statusCode}).';
        if (responseBody.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(responseBody);
            if (decoded is Map && decoded['message'] != null) {
              message = decoded['message'].toString();
            }
          } catch (_) {}
        }
        throw Exception(message);
      }

      if (responseBody.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(responseBody);
          if (decoded is Map && decoded['success'] == false) {
            throw Exception(
              decoded['message']?.toString() ?? 'Product image upload failed.',
            );
          }
        } catch (e) {
          if (e is Exception) rethrow;
        }
      }
    } catch (e, st) {
      debugPrint('Product Image Upload Error: $e\n$st');
      rethrow;
    }
  }

  // ============================================================
  // 6. GET SUPPLIERS
  // ============================================================

  Future<List<Map<String, dynamic>>> getSuppliersFromServer() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConfig.getSuppliers}?page=1&limit=1000'),
        headers: ApiConfig.jsonHeaders,
      );

      final body = _decodeResponse(response);

      if (body['success'] != true) {
        throw Exception(
          body['message']?.toString() ?? 'Unable to load suppliers.',
        );
      }

      final data = body['data'];

      if (data is! List) {
        throw Exception('Invalid supplier data received from server.');
      }

      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } on FormatException {
      throw Exception('Invalid response received from server.');
    } catch (e, st) {
      debugPrint('Supplier GET Error: $e\n$st');
      rethrow;
    }
  }

  // ============================================================
  // 7. STOCK & PRODUCT ACTION NOTIFICATIONS
  // ============================================================

Future<bool> triggerStockNotification({
    required int productId,
    required String actionType,
    required int changeQty,
    int? userId,
  }) async {
    try {
      final Map<String, dynamic> requestPayload = {
        'product_id': productId,
        'action_type': actionType,
        'change_qty': changeQty,
      };

      if (userId != null && userId > 0) {
        requestPayload['user_id'] = userId;
      }

      final response = await client.post(
        Uri.parse(ApiConfig.triggerStockStatus),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(requestPayload),
      );

      final data = _decodeResponse(response);
      return data['success'] == true;
    } catch (e, st) {
      debugPrint('Stock Trigger Error: $e\n$st');
      return false;
    }
  }

Future<bool> triggerProductActionNotification({
    required String title,
    required String message,
    required String notificationType,
    int? userId,
  }) async {
    try {
      final Map<String, dynamic> requestPayload = {
        'title': title,
        'message': message,
        'notification_type': notificationType,
      };

      if (userId != null && userId > 0) {
        requestPayload['user_id'] = userId;
      }

      final response = await client.post(
        Uri.parse(ApiConfig.triggerStockStatus),
        headers: ApiConfig.jsonHeaders,
        body: jsonEncode(requestPayload),
      );
      final data = _decodeResponse(response);
      return data['success'] == true;
    } catch (e, st) {
      debugPrint('Product action notification trigger error: $e\n$st');
      return false;
    }
  }
}