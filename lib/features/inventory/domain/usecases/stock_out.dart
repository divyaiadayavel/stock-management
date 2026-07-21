import '../repositories/inventory_repository.dart';

class StockOut {
  final InventoryRepository repository;

  const StockOut(this.repository);

  Future<bool> call({
    required int productId,
    required int quantity,
    String reason = "",
    String referenceType = "MANUAL",
    String referenceNumber = "",
    String remarks = "",
  }) async {
    return await repository.stockOut(
      productId: productId,
      quantity: quantity,
      reason: reason,
      referenceType: referenceType,
      referenceNumber: referenceNumber,
      remarks: remarks,
    );
  }
}