import '../entities/purchase_order.dart';
import '../repositories/inventory_repository.dart';

class CreatePurchaseOrder {
  final InventoryRepository repository;

  const CreatePurchaseOrder(this.repository);

  Future<bool> call(PurchaseOrder purchaseOrder) async {
    return await repository.createPurchaseOrder(
      purchaseOrder,
    );
  }
}