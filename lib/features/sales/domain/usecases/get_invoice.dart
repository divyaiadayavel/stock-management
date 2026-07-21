import '../../data/models/sale_model.dart';
import '../repositories/sales_repository.dart';

class GetInvoice {
  final SalesRepository repository;

  GetInvoice(this.repository);

  Future<SaleModel?> call(int saleId) async {
    return await repository.getInvoice(saleId);
  }
}