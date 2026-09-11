// ============================================================
// lib/features/inventory/domain/usecases/get_inventory_stock.dart
// ============================================================

import '../../../products/data/models/product_model.dart';
import '../repositories/inventory_repository.dart';


/// ============================================================
/// Get Inventory Stock
///
/// Retrieves inventory products using the selected:
///
/// - filter
/// - search
/// - sort
///
/// Filtering itself is handled by the backend.
/// ============================================================

class GetInventoryStock {
  final InventoryRepository repository;

  const GetInventoryStock(
    this.repository,
  );


  Future<List<Product>> call({
    String filter = 'all',
    String search = '',
    String sortBy = 'name_asc',
  }) {
    return repository.getInventoryProducts(
      filter: filter,
      search: search,
      sortBy: sortBy,
    );
  }
}