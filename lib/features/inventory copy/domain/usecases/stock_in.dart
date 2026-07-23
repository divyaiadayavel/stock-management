import '../repositories/inventory_repository.dart';

class StockIn {
  final InventoryRepository repository;

  const StockIn(this.repository);

  Future<bool> call({
    required int productId,
    required int quantity,
    required double unitCost,
    int? supplierId,
    String referenceType = "MANUAL",
    String referenceNumber = "",
    String remarks = "",
  }) async {
    return await repository.stockIn(
      productId: productId,
      quantity: quantity,
      unitCost: unitCost,
      supplierId: supplierId,
      referenceType: referenceType,
      referenceNumber: referenceNumber,
      remarks: remarks,
    );
  }
}