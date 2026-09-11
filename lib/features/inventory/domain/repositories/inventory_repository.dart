// ============================================================
// lib/features/inventory/domain/repositories/inventory_repository.dart
// ============================================================

import '../../../products/data/models/product_model.dart';

import '../entities/inventory_summary.dart';
import '../entities/purchase_order.dart';
import '../entities/stock_movement.dart';

/// ============================================================
/// Inventory Repository
///
/// Domain-level contract for inventory operations.
///
/// Backend/PHP is the source of truth.

/// ============================================================

abstract class InventoryRepository {
  // ==========================================================
  // Inventory Summary
  // ==========================================================

  Future<InventorySummary> getInventorySummary();

  // ==========================================================
  // Inventory Products
  // ==========================================================

  Future<List<Product>> getInventoryProducts({
    int page = 1,
    int limit = 500,
    String filter = 'all',
    String search = '',
    String sortBy = 'name_asc',
  });

  // ==========================================================
  // Low Stock
  // ==========================================================

  Future<List<Product>> getLowStockProducts();

  // ==========================================================
  // Product Search
  // ==========================================================

  Future<List<Product>> searchProducts(String query);

  // ==========================================================
  // Product By ID
  // ==========================================================

  Future<Product?> getProductById(int productId);

  // ==========================================================
  // Stock Movements
  // ==========================================================

  Future<List<StockMovement>> getStockMovements({
    int? productId,
    String? movementType,
  });

  // ==========================================================
  // Stock In
  // ==========================================================

  Future<bool> stockIn({
    required int productId,
    required int quantity,
    required double unitCost,
    int? supplierId,
    String referenceType = 'MANUAL',
    String referenceNumber = '',
    String remarks = '',
  });

  // ==========================================================
  // Stock Out
  // ==========================================================

  Future<bool> stockOut({
    required int productId,
    required int quantity,
    String reason = '',
    String referenceType = 'MANUAL',
    String referenceNumber = '',
    String remarks = '',
  });

  // ==========================================================
  // Purchase Orders
  // ==========================================================

  Future<List<PurchaseOrder>> getPurchaseOrders();

  Future<PurchaseOrder?> getPurchaseOrder(
    int purchaseOrderId,
  );

  Future<bool> createPurchaseOrder(
    PurchaseOrder purchaseOrder,
  );

  Future<bool> receivePurchaseOrder({
    required int purchaseOrderId,
    required List<Map<String, dynamic>> receivedItems,
    String remarks = '',
  });

  Future<bool> cancelPurchaseOrder(
    int purchaseOrderId,
  );
}