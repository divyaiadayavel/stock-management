import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/inventory_summary_model.dart';
import '../models/stock_movement_model.dart';
import '../models/purchase_order_model.dart';
import '../../../products/data/models/product_model.dart';

/// Remote data source for inventory‑specific API calls.
/// All calls go through the single `inventory.php` endpoint with an `action` parameter.
class InventoryRemoteDataSource {
  final http.Client client;

  InventoryRemoteDataSource({required this.client});

  // ============================================================
  // 1. Dashboard Summary
  // ============================================================
  Future<InventorySummaryModel> getInventorySummary() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConfig.inventory}?action=summary'),
        headers: ApiConfig.jsonHeaders,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return InventorySummaryModel.fromMap(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load inventory summary');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('getInventorySummary error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 2. Inventory Product List (paginated)
  // ============================================================
  Future<List<Product>> getInventoryProducts({
    int page = 1,
    int limit = 20,
    String search = '',
    String filter = '',
    String sortBy = 'name',
  }) async {
    try {
      final queryParams = {
        'action': 'products',
        'page': page.toString(),
        'limit': limit.toString(),
        'search': search,
        'filter': filter,
        'sort_by': sortBy,
      };
      final uri = Uri.parse(ApiConfig.inventory)
          .replace(queryParameters: queryParams);

      final response = await client.get(uri, headers: ApiConfig.jsonHeaders);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return _parseProducts(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load inventory products');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('getInventoryProducts error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 3. Low Stock Products
  // ============================================================
  Future<List<Product>> getLowStockProducts() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConfig.inventory}?action=low_stock'),
        headers: ApiConfig.jsonHeaders,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return _parseProducts(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load low stock products');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('getLowStockProducts error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 4. Stock In
  // ============================================================
  Future<bool> stockIn({
    required int productId,
    required int quantity,
    required double unitCost,
    int? supplierId,
    String referenceType = '',
    String referenceNumber = '',
    String remarks = '',
  }) async {
    try {
      final body = {
        'product_id': productId,
        'quantity': quantity,
        'unit_cost': unitCost,
        if (supplierId != null) 'supplier_id': supplierId,
        'reference_type': referenceType,
        'reference_number': referenceNumber,
        'remarks': remarks,
      };
      final response = await client.post(
        Uri.parse('${ApiConfig.inventory}?action=stock_in'),
        headers: ApiConfig.jsonHeaders,
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Stock in failed: ${response.statusCode}');
      }
    } catch (e) {
      print('stockIn error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 5. Stock Out
  // ============================================================
  Future<bool> stockOut({
    required int productId,
    required int quantity,
    required String reason,
    String referenceType = '',
    String referenceNumber = '',
    String remarks = '',
  }) async {
    try {
      final body = {
        'product_id': productId,
        'quantity': quantity,
        'reason': reason,
        'reference_type': referenceType,
        'reference_number': referenceNumber,
        'remarks': remarks,
      };
      final response = await client.post(
        Uri.parse('${ApiConfig.inventory}?action=stock_out'),
        headers: ApiConfig.jsonHeaders,
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Stock out failed: ${response.statusCode}');
      }
    } catch (e) {
      print('stockOut error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 6. Stock Movements (history)
  // ============================================================
  Future<List<StockMovementModel>> getStockMovements({
    int? productId,
    String? movementType,
  }) async {
    try {
      final queryParams = {
        'action': 'movements',
        if (productId != null) 'product_id': productId.toString(),
        if (movementType != null && movementType.isNotEmpty)
          'movement_type': movementType,
      };
      final uri = Uri.parse(ApiConfig.inventory)
          .replace(queryParameters: queryParams);

      final response = await client.get(uri, headers: ApiConfig.jsonHeaders);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return _parseMovements(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load stock movements');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('getStockMovements error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 7. List Purchase Orders
  // ============================================================
  Future<List<PurchaseOrderModel>> getPurchaseOrders() async {
    try {
      final response = await client.get(
        Uri.parse('${ApiConfig.inventory}?action=purchases'),
        headers: ApiConfig.jsonHeaders,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return _parsePurchaseOrders(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load purchase orders');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('getPurchaseOrders error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 8. Single Purchase Order (with items)
  // ============================================================
  Future<PurchaseOrderModel?> getPurchaseOrder(int purchaseOrderId) async {
    try {
      final uri = Uri.parse(ApiConfig.inventory)
          .replace(queryParameters: {
            'action': 'purchase',
            'id': purchaseOrderId.toString(),
          });
      final response = await client.get(uri, headers: ApiConfig.jsonHeaders);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return PurchaseOrderModel.fromMap(data['data']);
        } else {
          return null;
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('getPurchaseOrder error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 9. Create Purchase Order
  // ============================================================
  Future<bool> createPurchaseOrder(PurchaseOrderModel purchaseOrder) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConfig.inventory}?action=create_purchase'),
        headers: ApiConfig.jsonHeaders,
        body: json.encode(purchaseOrder.toMap()),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Create purchase order failed: ${response.statusCode}');
      }
    } catch (e) {
      print('createPurchaseOrder error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 10. Receive Purchase Order
  // ============================================================
  Future<bool> receivePurchaseOrder({
    required int purchaseOrderId,
    required List<Map<String, dynamic>> receivedItems,
    String remarks = '',
  }) async {
    try {
      final body = {
        'purchase_order_id': purchaseOrderId,
        'received_items': receivedItems,
        'remarks': remarks,
      };
      final response = await client.post(
        Uri.parse('${ApiConfig.inventory}?action=receive_purchase'),
        headers: ApiConfig.jsonHeaders,
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Receive purchase order failed: ${response.statusCode}');
      }
    } catch (e) {
      print('receivePurchaseOrder error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 11. Cancel Purchase Order
  // ============================================================
  Future<bool> cancelPurchaseOrder(int purchaseOrderId) async {
    try {
      final body = {'id': purchaseOrderId};
      final response = await client.post(
        Uri.parse('${ApiConfig.inventory}?action=cancel_purchase'),
        headers: ApiConfig.jsonHeaders,
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Cancel purchase order failed: ${response.statusCode}');
      }
    } catch (e) {
      print('cancelPurchaseOrder error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 12. Search Products (autocomplete) – kept as stubs
  // ============================================================
  Future<List<Product>> searchProducts(String query) async {
    // This could be implemented using action=search if needed.
    // For now, return empty list.
    return [];
  }

  Future<Product?> getProductById(int productId) async {
    // Could be implemented with action=product and id param.
    // For now, return null.
    return null;
  }

  // ============================================================
  // Private Helpers
  // ============================================================
  List<Product> _parseProducts(dynamic data) {
    if (data is List) {
      return data.map((item) => Product.fromMap(item)).toList();
    }
    return [];
  }

  List<StockMovementModel> _parseMovements(dynamic data) {
    if (data is List) {
      return data.map((item) => StockMovementModel.fromMap(item)).toList();
    }
    return [];
  }

  List<PurchaseOrderModel> _parsePurchaseOrders(dynamic data) {
    if (data is List) {
      return data.map((item) => PurchaseOrderModel.fromMap(item)).toList();
    }
    return [];
  }
}