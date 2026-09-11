import '../entities/payable_supplier.dart';
import '../repositories/reports_repository.dart';

class GetPayableSuppliers {
  final ReportsRepository repository;

  GetPayableSuppliers(this.repository);

  Future<List<PayableSupplier>> call() async {
    return await repository.getPayableSuppliers();
  }
}
