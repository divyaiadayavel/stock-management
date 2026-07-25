import '../../../products/data/models/product_model.dart';
import '../repositories/inventory_repository.dart';

class GetLowStock {
  final InventoryRepository repository;

  const GetLowStock(this.repository);

  Future<List<Product>> call() async {
    return await repository.getLowStockProducts();
  }
}