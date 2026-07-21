import '../../../products/data/models/product_model.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryStock {
  final InventoryRepository repository;

  const GetInventoryStock(this.repository);

  Future<List<Product>> call({
    String filter = "all",
    String search = "",
    String sortBy = "name_asc",
  }) async {
    return await repository.getInventoryProducts(
      filter: filter,
      search: search,
      sortBy: sortBy,
    );
  }
}