// ============================================================
// lib/features/inventory/data/datasources/inventory_remote_datasource.dart
// ============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';

import '../models/inventory_summary_model.dart';
import '../models/stock_movement_model.dart';
import '../models/purchase_order_model.dart';

import '../../../products/data/models/product_model.dart';


/// ============================================================
/// Inventory Remote Data Source
///
/// All inventory API requests use:
///
/// ApiConfig.inventory
///
/// which points to:
///
/// /api/inventory/inventory.php
///
/// The backend is the source of truth for:
///
/// - Inventory summary counts
/// - All products
/// - Low stock
/// - Out of stock
/// - Expiring within 30 days
/// - Expired products
/// - Stock movements
/// - Purchase orders
/// ============================================================

class InventoryRemoteDataSource {
  final http.Client client;

  InventoryRemoteDataSource({
    required this.client,
  });


  // ============================================================
  // 1. Inventory Summary
  //
  // Returns:
  //
  // - total_products
  // - total_units
  // - inventory_value
  // - low_stock_products
  // - out_of_stock_products
  // - expiring_products
  // - expired_products
  // - today_stock_in
  // - today_stock_out
  // ============================================================

  Future<InventorySummaryModel>
      getInventorySummary() async {
    try {
      final response = await client.get(
        Uri.parse(
          '${ApiConfig.inventory}?action=summary',
        ),
        headers: ApiConfig.jsonHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server error: ${response.statusCode}',
        );
      }

      final decoded =
          json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid inventory summary response',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message'] ??
              'Failed to load inventory summary',
        );
      }

      final data = decoded['data'];

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'Invalid inventory summary data',
        );
      }

      return InventorySummaryModel.fromMap(
        data,
      );
    } catch (e) {
      print(
        'getInventorySummary error: $e',
      );
      rethrow;
    }
  }


  // ============================================================
  // 2. Inventory Product List
  //
  // Supported filters:
  //
  // all
  // low
  // out
  // expiring
  // expired
  //
  // Filtering is handled by inventory.php.
  //
  // Flutter does NOT calculate expiry dates locally.
  // ============================================================

  Future<List<Product>>
      getInventoryProducts({
    int page = 1,
    int limit = 20,
    String search = '',
    String filter = 'all',
    String sortBy = 'name_asc',
  }) async {
    try {
      final queryParams = {
        'action': 'products',
        'page': page.toString(),
        'limit': limit.toString(),
        'search': search.trim(),
        'filter': filter.isEmpty
            ? 'all'
            : filter,
        'sort_by': sortBy,
      };

      final uri = Uri.parse(
        ApiConfig.inventory,
      ).replace(
        queryParameters: queryParams,
      );

      final response = await client.get(
        uri,
        headers: ApiConfig.jsonHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server error: ${response.statusCode}',
        );
      }

      final decoded =
          json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid inventory products response',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message'] ??
              'Failed to load inventory products',
        );
      }

      return _parseProducts(
        decoded['data'],
      );
    } catch (e) {
      print(
        'getInventoryProducts error: $e',
      );
      rethrow;
    }
  }


  // ============================================================
  // 3. Low Stock Products
  //
  // Kept as a dedicated endpoint because other inventory
  // features may still use it.
  //
  // This is NOT used by the StockScreen filter.
  // ============================================================

  Future<List<Product>>
      getLowStockProducts() async {
    try {
      final response = await client.get(
        Uri.parse(
          '${ApiConfig.inventory}?action=low_stock',
        ),
        headers: ApiConfig.jsonHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server error: ${response.statusCode}',
        );
      }

      final decoded =
          json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid low stock response',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message'] ??
              'Failed to load low stock products',
        );
      }

      return _parseProducts(
        decoded['data'],
      );
    } catch (e) {
      print(
        'getLowStockProducts error: $e',
      );
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
        if (supplierId != null)
          'supplier_id': supplierId,
        'reference_type': referenceType,
        'reference_number': referenceNumber,
        'remarks': remarks,
      };

      final response = await client.post(
        Uri.parse(
          '${ApiConfig.inventory}?action=stock_in',
        ),
        headers: ApiConfig.jsonHeaders,
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Stock in failed: ${response.statusCode}',
        );
      }

      final decoded =
          json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid stock in response',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message'] ??
              'Stock in failed',
        );
      }

      return true;
    } catch (e) {
      print(
        'stockIn error: $e',
      );
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
        Uri.parse(
          '${ApiConfig.inventory}?action=stock_out',
        ),
        headers: ApiConfig.jsonHeaders,
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Stock out failed: ${response.statusCode}',
        );
      }

      final decoded =
          json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid stock out response',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message'] ??
              'Stock out failed',
        );
      }

      return true;
    } catch (e) {
      print(
        'stockOut error: $e',
      );
      rethrow;
    }
  }


  // ============================================================
  // 6. Stock Movements
  // ============================================================

  Future<List<StockMovementModel>>
      getStockMovements({
    int? productId,
    String? movementType,
  }) async {
    try {
      final queryParams = {
        'action': 'movements',
        if (productId != null)
          'product_id':
              productId.toString(),
        if (movementType != null &&
            movementType.isNotEmpty)
          'movement_type':
              movementType,
      };

      final uri = Uri.parse(
        ApiConfig.inventory,
      ).replace(
        queryParameters: queryParams,
      );

      final response = await client.get(
        uri,
        headers: ApiConfig.jsonHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server error: ${response.statusCode}',
        );
      }

      final decoded =
          json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid stock movements response',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message'] ??
              'Failed to load stock movements',
        );
      }

      return _parseMovements(
        decoded['data'],
      );
    } catch (e) {
      print(
        'getStockMovements error: $e',
      );
      rethrow;
    }
  }


  // ============================================================
  // 7. List Purchase Orders
  // ============================================================

  Future<List<PurchaseOrderModel>>
      getPurchaseOrders() async {
    try {
      final response = await client.get(
        Uri.parse(
          '${ApiConfig.inventory}?action=purchases',
        ),
        headers: ApiConfig.jsonHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server error: ${response.statusCode}',
        );
      }

      final decoded =
          json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid purchase orders response',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message'] ??
              'Failed to load purchase orders',
        );
      }

      return _parsePurchaseOrders(
        decoded['data'],
      );
    } catch (e) {
      print(
        'getPurchaseOrders error: $e',
      );
      rethrow;
    }
  }


  // ============================================================
  // 8. Single Purchase Order
  // ============================================================

  Future<PurchaseOrderModel?>
      getPurchaseOrder(
    int purchaseOrderId,
  ) async {
    try {
      final uri = Uri.parse(
        ApiConfig.inventory,
      ).replace(
        queryParameters: {
          'action': 'purchase',
          'id': purchaseOrderId.toString(),
        },
      );

      final response = await client.get(
        uri,
        headers: ApiConfig.jsonHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server error: ${response.statusCode}',
        );
      }

      final decoded =
          json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid purchase order response',
        );
      }

      if (decoded['success'] == true &&
          decoded['data'] != null) {
        return PurchaseOrderModel.fromMap(
          decoded['data'],
        );
      }

      return null;
    } catch (e) {
      print(
        'getPurchaseOrder error: $e',
      );
      rethrow;
    }
  }


  // ============================================================
  // 9. Create Purchase Order
  // ============================================================

  Future<bool> createPurchaseOrder(
    PurchaseOrderModel purchaseOrder,
  ) async {
    try {
      final response = await client.post(
        Uri.parse(
          '${ApiConfig.inventory}?action=create_purchase',
        ),
        headers: ApiConfig.jsonHeaders,
        body: json.encode(
          purchaseOrder.toMap(),
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Create purchase order failed: '
          '${response.statusCode}',
        );
      }

      final decoded =
          json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid create purchase order response',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message'] ??
              'Create purchase order failed',
        );
      }

      return true;
    } catch (e) {
      print(
        'createPurchaseOrder error: $e',
      );
      rethrow;
    }
  }


  // ============================================================
  // 10. Receive Purchase Order
  // ============================================================

  Future<bool> receivePurchaseOrder({
    required int purchaseOrderId,
    required List<Map<String, dynamic>>
        receivedItems,
    String remarks = '',
  }) async {
    try {
      final body = {
        'purchase_order_id':
            purchaseOrderId,
        'received_items':
            receivedItems,
        'remarks':
            remarks,
      };

      final response = await client.post(
        Uri.parse(
          '${ApiConfig.inventory}?action=receive_purchase',
        ),
        headers: ApiConfig.jsonHeaders,
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Receive purchase order failed: '
          '${response.statusCode}',
        );
      }

      final decoded =
          json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid receive purchase order response',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message'] ??
              'Receive purchase order failed',
        );
      }

      return true;
    } catch (e) {
      print(
        'receivePurchaseOrder error: $e',
      );
      rethrow;
    }
  }


  // ============================================================
  // 11. Cancel Purchase Order
  // ============================================================

  Future<bool> cancelPurchaseOrder(
    int purchaseOrderId,
  ) async {
    try {
      final body = {
        'id': purchaseOrderId,
      };

      final response = await client.post(
        Uri.parse(
          '${ApiConfig.inventory}?action=cancel_purchase',
        ),
        headers: ApiConfig.jsonHeaders,
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Cancel purchase order failed: '
          '${response.statusCode}',
        );
      }

      final decoded =
          json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid cancel purchase order response',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message'] ??
              'Cancel purchase order failed',
        );
      }

      return true;
    } catch (e) {
      print(
        'cancelPurchaseOrder error: $e',
      );
      rethrow;
    }
  }


  // ============================================================
  // 12. Search Products
  // ============================================================

  Future<List<Product>> searchProducts(
    String query,
  ) async {
    final trimmedQuery =
        query.trim();

    if (trimmedQuery.isEmpty) {
      return [];
    }

    /*
     * Use the existing inventory.php search action.
     */

    try {
      final uri = Uri.parse(
        ApiConfig.inventory,
      ).replace(
        queryParameters: {
          'action': 'search',
          'q': trimmedQuery,
          'limit': '10',
        },
      );

      final response = await client.get(
        uri,
        headers: ApiConfig.jsonHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server error: ${response.statusCode}',
        );
      }

      final decoded =
          json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid product search response',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message'] ??
              'Product search failed',
        );
      }

      return _parseProducts(
        decoded['data'],
      );
    } catch (e) {
      print(
        'searchProducts error: $e',
      );
      rethrow;
    }
  }


  // ============================================================
  // 13. Get Product By ID
  // ============================================================

  Future<Product?> getProductById(
    int productId,
  ) async {
    try {
      final uri = Uri.parse(
        ApiConfig.inventory,
      ).replace(
        queryParameters: {
          'action': 'product',
          'product_id':
              productId.toString(),
        },
      );

      final response = await client.get(
        uri,
        headers: ApiConfig.jsonHeaders,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server error: ${response.statusCode}',
        );
      }

      final decoded =
          json.decode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid product response',
        );
      }

      if (decoded['success'] != true ||
          decoded['data'] == null) {
        return null;
      }

      final data =
          decoded['data'];

      if (data is! Map<String, dynamic>) {
        return null;
      }

      return Product.fromMap(
        data,
      );
    } catch (e) {
      print(
        'getProductById error: $e',
      );
      rethrow;
    }
  }


  // ============================================================
  // Private Helpers
  // ============================================================

  List<Product> _parseProducts(
    dynamic data,
  ) {
    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(
          Product.fromMap,
        )
        .toList();
  }


  List<StockMovementModel>
      _parseMovements(
    dynamic data,
  ) {
    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(
          StockMovementModel.fromMap,
        )
        .toList();
  }


  List<PurchaseOrderModel>
      _parsePurchaseOrders(
    dynamic data,
  ) {
    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(
          PurchaseOrderModel.fromMap,
        )
        .toList();
  }
}