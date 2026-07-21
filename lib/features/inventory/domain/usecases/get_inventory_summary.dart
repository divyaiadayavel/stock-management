import '../entities/inventory_summary.dart';
import '../repositories/inventory_repository.dart';

class GetInventorySummary {
  final InventoryRepository repository;

  const GetInventorySummary(this.repository);

  Future<InventorySummary> call() async {
    return await repository.getInventorySummary();
  }
}