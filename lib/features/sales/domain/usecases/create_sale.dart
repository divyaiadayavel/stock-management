import '../repositories/sales_repository.dart';
import '../../data/models/sale_model.dart';

class CreateSale {
  final SalesRepository repository;

  CreateSale(this.repository);

  Future<int> call(SaleModel sale) async {
    return await repository.createSale(sale);
  }
}