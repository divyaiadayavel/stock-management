import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../../domain/entities/inventory_summary.dart';
import '../../../products/data/models/product_model.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/purchase_order.dart';
import '../models/purchase_order_model.dart'; // for the factory

/// Thin repository – only forwards calls to the data source.
/// All mapping (entity ↔ model) is done via model factories.
class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource dataSource;

  InventoryRepositoryImpl({required this.dataSource});

  @override
  Future<InventorySummary> getInventorySummary() {
    return dataSource.getInventorySummary();
  }

  @override
  Future<List<Product>> getInventoryProducts({
    int page = 1,
    int limit = 20,
    String search = '',
    String filter = '',
    String sortBy = 'name',
  }) {
    return dataSource.getInventoryProducts(
      page: page,
      limit: limit,
      search: search,
      filter: filter,
      sortBy: sortBy,
    );
  }

  @override
  Future<List<Product>> getLowStockProducts() {
    return dataSource.getLowStockProducts();
  }

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

  @override
  Future<bool> stockOut({
    required int productId,
    required int quantity,
    String reason = "",
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

  @override
  Future<List<StockMovement>> getStockMovements({
    int? productId,
    String? movementType,
  }) {
    return dataSource.getStockMovements(
      productId: productId,
      movementType: movementType,
    );
  }

  @override
  Future<List<PurchaseOrder>> getPurchaseOrders() {
    return dataSource.getPurchaseOrders();
  }

  @override
  Future<PurchaseOrder?> getPurchaseOrder(int purchaseOrderId) {
    return dataSource.getPurchaseOrder(purchaseOrderId);
  }

  @override
  Future<bool> createPurchaseOrder(PurchaseOrder purchaseOrder) {
    // ✅ Convert domain entity to model using dedicated factory
    final model = purchaseOrder as PurchaseOrderModel;
    return dataSource.createPurchaseOrder(model);
  }

  @override
  Future<bool> receivePurchaseOrder({
    required int purchaseOrderId,
    required List<Map<String, dynamic>> receivedItems,
    String remarks = '',
  }) {
    return dataSource.receivePurchaseOrder(
      purchaseOrderId: purchaseOrderId,
      receivedItems: receivedItems,
      remarks: remarks,
    );
  }

  @override
  Future<bool> cancelPurchaseOrder(int purchaseOrderId) {
    return dataSource.cancelPurchaseOrder(purchaseOrderId);
  }

  @override
Future<List<Product>> searchProducts(String query) {
  return dataSource.searchProducts(query);
}

@override
Future<Product?> getProductById(int productId) {
  return dataSource.getProductById(productId);
}
}

