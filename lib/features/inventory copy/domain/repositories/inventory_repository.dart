import '../../../products/data/models/product_model.dart';
import '../entities/inventory_summary.dart';
import '../entities/purchase_order.dart';
import '../entities/stock_movement.dart';

abstract class InventoryRepository {
  // ==========================================================
  // Inventory Dashboard
  // ==========================================================

  Future<InventorySummary> getInventorySummary();

  // ==========================================================
  // Stock
  // ==========================================================

  Future<List<Product>> getInventoryProducts({
    String filter = "all",
    String search = "",
    String sortBy = "name_asc",
  });

  Future<List<Product>> getLowStockProducts();

  Future<List<Product>> searchProducts(String query);

  Future<Product?> getProductById(int productId);

  // ==========================================================
  // Stock Movements
  // ==========================================================

  Future<List<StockMovement>> getStockMovements({
    int? productId,
    String? movementType,
  });

  Future<bool> stockIn({
    required int productId,
    required int quantity,
    required double unitCost,
    int? supplierId,
    String referenceType = "MANUAL",
    String referenceNumber = "",
    String remarks = "",
  });

  Future<bool> stockOut({
    required int productId,
    required int quantity,
    String reason,
    String referenceType = "MANUAL",
    String referenceNumber = "",
    String remarks = "",
  });

  // ==========================================================
  // Purchase Orders
  // ==========================================================

  Future<List<PurchaseOrder>> getPurchaseOrders();

  Future<PurchaseOrder?> getPurchaseOrder(int purchaseOrderId);

  Future<bool> createPurchaseOrder(PurchaseOrder purchaseOrder);

  Future<bool> receivePurchaseOrder({
    required int purchaseOrderId,
    required List<Map<String, dynamic>> receivedItems,
    String remarks = "",
  });

  Future<bool> cancelPurchaseOrder(int purchaseOrderId);
}