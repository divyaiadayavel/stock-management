// ============================================================
// lib/features/inventory/data/repositories/inventory_repository_impl.dart
// ============================================================

import '../../domain/repositories/inventory_repository.dart';

import '../datasources/inventory_remote_datasource.dart';

import '../../domain/entities/inventory_summary.dart';
import '../../../products/data/models/product_model.dart';

import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/purchase_order.dart';

import '../models/purchase_order_model.dart';


/// ============================================================
/// Inventory Repository Implementation
///
/// Thin repository layer.
///
/// Responsibilities:
/// - Forward domain requests to remote data source.
/// - Keep domain layer independent from HTTP/API details.
///
/// Filtering, expiry calculations and inventory counts are
/// handled by the backend through InventoryRemoteDataSource.
/// ============================================================

class InventoryRepositoryImpl
    implements InventoryRepository {
  final InventoryRemoteDataSource dataSource;

  InventoryRepositoryImpl({
    required this.dataSource,
  });


  // ==========================================================
  // Inventory Summary
  // ==========================================================

  @override
  Future<InventorySummary>
      getInventorySummary() {
    return dataSource.getInventorySummary();
  }


  // ==========================================================
  // Inventory Products
  //
  // Supported filters:
  // - all
  // - low
  // - out
  // - expiring
  // - expired
  //
  // The selected filter is forwarded unchanged to the
  // remote data source.
  // ==========================================================

  @override
  Future<List<Product>>
      getInventoryProducts({
    int page = 1,
    int limit = 500,
    String search = '',
    String filter = 'all',
    String sortBy = 'name_asc',
  }) {
    return dataSource.getInventoryProducts(
      page: page,
      limit: limit,
      search: search,
      filter: filter.isEmpty
          ? 'all'
          : filter,
      sortBy: sortBy,
    );
  }


  // ==========================================================
  // Low Stock Products
  // ==========================================================

  @override
  Future<List<Product>>
      getLowStockProducts() {
    return dataSource.getLowStockProducts();
  }


  // ==========================================================
  // Stock In
  // ==========================================================

  @override
  Future<bool> stockIn({
    required int productId,
    required int quantity,
    required double unitCost,
    int? supplierId,
    String referenceType = '',
    String referenceNumber = '',
    String remarks = '',
  }) {
    return dataSource.stockIn(
      productId: productId,
      quantity: quantity,
      unitCost: unitCost,
      supplierId: supplierId,
      referenceType: referenceType,
      referenceNumber: referenceNumber,
      remarks: remarks,
    );
  }


  // ==========================================================
  // Stock Out
  // ==========================================================

  @override
  Future<bool> stockOut({
    required int productId,
    required int quantity,
    String reason = '',
    String referenceType = '',
    String referenceNumber = '',
    String remarks = '',
  }) {
    return dataSource.stockOut(
      productId: productId,
      quantity: quantity,
      reason: reason,
      referenceType: referenceType,
      referenceNumber: referenceNumber,
      remarks: remarks,
    );
  }


  // ==========================================================
  // Stock Movements
  // ==========================================================

  @override
  Future<List<StockMovement>>
      getStockMovements({
    int? productId,
    String? movementType,
  }) {
    return dataSource.getStockMovements(
      productId: productId,
      movementType: movementType,
    );
  }


  // ==========================================================
  // Purchase Orders
  // ==========================================================

  @override
  Future<List<PurchaseOrder>>
      getPurchaseOrders() {
    return dataSource.getPurchaseOrders();
  }


  // ==========================================================
  // Single Purchase Order
  // ==========================================================

  @override
  Future<PurchaseOrder?>
      getPurchaseOrder(
    int purchaseOrderId,
  ) {
    return dataSource.getPurchaseOrder(
      purchaseOrderId,
    );
  }


  // ==========================================================
  // Create Purchase Order
  // ==========================================================

  @override
  Future<bool> createPurchaseOrder(
    PurchaseOrder purchaseOrder,
  ) {
    /*
     * PurchaseOrderModel is the data-layer implementation
     * used by the remote data source.
     *
     * Preserve the existing architecture where the domain
     * entity is converted to its data model before sending
     * it to the API.
     */

    final model =
        purchaseOrder as PurchaseOrderModel;

    return dataSource.createPurchaseOrder(
      model,
    );
  }


  // ==========================================================
  // Receive Purchase Order
  // ==========================================================

  @override
  Future<bool> receivePurchaseOrder({
    required int purchaseOrderId,
    required List<Map<String, dynamic>>
        receivedItems,
    String remarks = '',
  }) {
    return dataSource.receivePurchaseOrder(
      purchaseOrderId: purchaseOrderId,
      receivedItems: receivedItems,
      remarks: remarks,
    );
  }


  // ==========================================================
  // Cancel Purchase Order
  // ==========================================================

  @override
  Future<bool> cancelPurchaseOrder(
    int purchaseOrderId,
  ) {
    return dataSource.cancelPurchaseOrder(
      purchaseOrderId,
    );
  }


  // ==========================================================
  // Product Search
  // ==========================================================

  @override
  Future<List<Product>>
      searchProducts(
    String query,
  ) {
    return dataSource.searchProducts(
      query,
    );
  }


  // ==========================================================
  // Get Product By ID
  // ==========================================================

  @override
  Future<Product?>
      getProductById(
    int productId,
  ) {
    return dataSource.getProductById(
      productId,
    );
  }
}