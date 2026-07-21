import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class CreateSupplier {
  final SupplierRepository repository;

  CreateSupplier(this.repository);

  Future<int> call(Supplier supplier) async {
    return await repository.createSupplier(supplier);
  }
}