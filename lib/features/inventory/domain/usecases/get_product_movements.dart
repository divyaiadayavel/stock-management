import '../entities/stock_movement.dart';
import '../repositories/inventory_repository.dart';

class GetProductMovements {
  final InventoryRepository repository;

  const GetProductMovements(this.repository);

  Future<List<StockMovement>> call({
    int? productId,
    String? movementType,
  }) async {
    return await repository.getStockMovements(
      productId: productId,
      movementType: movementType,
    );
  }
}