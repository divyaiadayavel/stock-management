import '../repositories/inventory_repository.dart';

class ReceivePurchaseOrder {
  final InventoryRepository repository;

  const ReceivePurchaseOrder(this.repository);

  Future<bool> call({
    required int purchaseOrderId,
    required List<Map<String, dynamic>> receivedItems,
    String remarks = "",
  }) async {
    return await repository.receivePurchaseOrder(
      purchaseOrderId: purchaseOrderId,
      receivedItems: receivedItems,
      remarks: remarks,
    );
  }
}